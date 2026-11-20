#!/usr/bin/env python3
"""Disposable process tests: no real PetClinic, Docker or host init mutation."""
import json,os,subprocess,sys,tempfile,unittest
from pathlib import Path
HELPER=Path(__file__).with_name("managed_process.py")
class TestOwnership(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
  self.jar=Path(self.tmp.name)/"sample.jar";self.jar.write_bytes(b"test")
  self.record=Path(self.tmp.name)/"owned.json";self.procs=[]
 def spawn(self):
  p=subprocess.Popen([sys.executable,"-c","import time;time.sleep(20)","-jar",str(self.jar)])
  self.procs.append(p);return p
 def tearDown(self):
  for p in self.procs:
   if p.poll() is None:
    p.terminate()
    try:p.wait(timeout=2)
    except subprocess.TimeoutExpired:p.kill();p.wait(timeout=2)
   else:p.wait()
 def call(self,*args):return subprocess.run([sys.executable,str(HELPER),*map(str,args)],capture_output=True,text=True)
 def own(self,p):
  r=self.call("record","--file",self.record,"--jar",self.jar,"--pid",p.pid)
  self.assertEqual(r.returncode,0,r.stderr)
 def test_stop_only_owned(self):
  owned=self.spawn();other=self.spawn();self.own(owned)
  result=self.call("stop","--file",self.record,"--grace",0.2)
  self.assertEqual(result.returncode,0,result.stderr);owned.wait(timeout=3)
  self.assertIsNone(other.poll());self.assertFalse(self.record.exists())
 def test_stale_pid_record_does_not_signal(self):
  p=self.spawn();self.own(p);d=json.loads(self.record.read_text());d["start_ticks"]+=1;self.record.write_text(json.dumps(d))
  self.assertEqual(self.call("stop","--file",self.record).returncode,0);self.assertIsNone(p.poll())
 def test_wrong_jar_rejected(self):
  p=self.spawn();wrong=Path(self.tmp.name)/"other.jar";wrong.write_bytes(b"fake")
  self.assertNotEqual(self.call("record","--file",self.record,"--jar",wrong,"--pid",p.pid).returncode,0)
  self.assertIsNone(p.poll())
 def test_cleanup_idempotent(self):
  p=self.spawn();self.own(p)
  self.assertEqual(self.call("stop","--file",self.record).returncode,0)
  self.assertEqual(self.call("stop","--file",self.record).returncode,0)
 def test_duplicate_ownership_refused(self):
  p=self.spawn();self.own(p)
  self.assertNotEqual(self.call("record","--file",self.record,"--jar",self.jar,"--pid",p.pid).returncode,0)
 def test_host_pid1_refused(self):
  self.assertNotEqual(self.call("record","--file",self.record,"--jar",self.jar,"--pid",1).returncode,0)
if __name__=="__main__":unittest.main(verbosity=2)
