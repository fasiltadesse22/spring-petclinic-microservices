#!/usr/bin/env python3
"""Safely control only recorded Linux process instances using pidfds."""
import argparse
import json
import os
from pathlib import Path
import signal
import sys
import tempfile
import time

def info(pid):
    try:
        raw=Path(f"/proc/{pid}/stat").read_text()
        fields=raw[raw.rfind(")")+2:].split()
        args=[v.decode("utf-8","surrogateescape") for v in Path(f"/proc/{pid}/cmdline").read_bytes().split(b"\0") if v]
        return fields[0],int(fields[19]),args
    except (OSError,ValueError,IndexError):return None

def matches(record):
    pid=record.get("pid")
    if not isinstance(pid,int) or pid<2:return False
    value=info(pid)
    if not value:return False
    state,start,args=value
    return state not in ("Z","X","x") and start==record.get("start_ticks") and any(
        args[i]=="-jar" and os.path.realpath(args[i+1])==record.get("jar") for i in range(len(args)-1)
    )

def read(path):
    try:
        value=json.loads(path.read_text())
        if not isinstance(value,dict):raise ValueError("not an object")
        return value
    except FileNotFoundError:return None
    except (ValueError,OSError) as exc:raise RuntimeError(f"invalid ownership file {path}: {exc}")

def record(path,pid,jar):
    jar=os.path.realpath(jar)
    if not os.path.isfile(jar):raise RuntimeError(f"missing jar: {jar}")
    if path.exists():raise RuntimeError(f"existing ownership record (review before deletion): {path}")
    for _ in range(35):
        value=info(pid)
        if value and value[0] not in ("Z","X","x") and any(
            value[2][i]=="-jar" and os.path.realpath(value[2][i+1])==jar for i in range(len(value[2])-1)
        ):break
        time.sleep(.04)
    else:raise RuntimeError(f"PID {pid} does not run expected jar {jar}")
    path.parent.mkdir(parents=True,exist_ok=True)
    fd,tmp=tempfile.mkstemp(prefix=".owned-",dir=str(path.parent))
    try:
        with os.fdopen(fd,"w") as out:json.dump({"pid":pid,"start_ticks":value[1],"jar":jar},out)
        os.replace(tmp,path)
    finally:
        if os.path.exists(tmp):os.unlink(tmp)
    print(f"Owned PID {pid} recorded")

def stop(path,grace):
    value=read(path)
    if value is None:return
    if not matches(value):
        print(f"Stale/exited ownership record: {path}; no signal sent")
        path.unlink(missing_ok=True);return
    if not hasattr(os,"pidfd_open") or not hasattr(signal,"pidfd_send_signal"):
        raise RuntimeError("pidfd signaling unavailable; refuse unsafe numeric-PID fallback")
    try:fd=os.pidfd_open(value["pid"])
    except ProcessLookupError:path.unlink(missing_ok=True);return
    try:
        if not matches(value):raise RuntimeError("identity changed before signaling; no signal sent")
        try:signal.pidfd_send_signal(fd,signal.SIGTERM,None,0)
        except ProcessLookupError:pass
        deadline=time.monotonic()+grace
        while matches(value) and time.monotonic()<deadline:time.sleep(.05)
        if matches(value):
            print(f"Escalating exact owned process instance {value['pid']} via pidfd",file=sys.stderr)
            try:signal.pidfd_send_signal(fd,signal.SIGKILL,None,0)
            except ProcessLookupError:pass
            deadline=time.monotonic()+3
            while matches(value) and time.monotonic()<deadline:time.sleep(.05)
        if matches(value):raise RuntimeError("owned instance remains alive; record retained")
        path.unlink(missing_ok=True)
        print(f"Owned PID {value['pid']} exited")
    finally:os.close(fd)

def main():
    p=argparse.ArgumentParser();sub=p.add_subparsers(dest="cmd",required=True)
    a=sub.add_parser("record");a.add_argument("--file",type=Path,required=True)
    a.add_argument("--pid",type=int,required=True);a.add_argument("--jar",type=Path,required=True)
    for op in ("check","stop"):
        a=sub.add_parser(op);a.add_argument("--file",type=Path,required=True)
        if op=="stop":a.add_argument("--grace",type=float,default=8)
    a=p.parse_args()
    try:
        if a.cmd=="record":record(a.file,a.pid,a.jar)
        elif a.cmd=="check":sys.exit(0 if matches(read(a.file) or {}) else 1)
        else:
            if not 0<=a.grace<=120:raise RuntimeError("grace out of range")
            stop(a.file,a.grace)
    except RuntimeError as exc:print(f"Ownership failure: {exc}",file=sys.stderr);sys.exit(2)
if __name__=="__main__":main()
