#!/usr/bin/python
#
# Copyright (c) 2016 The Ontario Institute for Cancer Research. All rights reserved.
#
# This program and the accompanying materials are made available under the terms of the GNU Public License v3.0.
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from org.apache.pig.scripting import *
from org.icgc.dcc.downloader.core import SchemaUtil
from org.icgc.dcc.etl.exporter.pig.storage import StaticMultiStorage
from org.icgc.dcc.etl.exporter.pig.storage import DynamicStorage
from subprocess import call
import os, os.path, sys
import getopt
sys.path.append(os.path.dirname(sys.argv[0]))
########CONTROL SETTINGS###########
from core import *

params = {
          'DYNAMIC_BLOCK_SIZE': '5000',
          'DEFAULT_PARALLEL': 100,
         }

########HADOOP JOB CONF SETTINGS###########
Pig.set("mapred.child.java.opts", "-Xms2G -Xmx8G")
Pig.set("mapred.reduce.parallel.copies", "30")
Pig.set("mapred.task.timeout", "14400000")
Pig.set("dfs.replication", "2")
Pig.set("pig.udf.profile", "false")
Pig.set("pig.cachedbag.memusage", "0.3")
Pig.set("dfs.blocksize", "134217728")
Pig.set("mapred.output.compression.type","BLOCK")


####### DATA PROCESSING ###########
def exportDynamicData(type):
  tmp_dynamic = tmp_dynamic_root + "/" + release + "/" + type
  tmp_hfile = tmp_hfile_root + "/" + release + "/" + type

  # remove tmp directory
  Pig.fs("rm -r -skipTrash " + tmp_hfile)
  Pig.fs("rm -r -skipTrash " + tmp_dynamic)

  params["RELEASE_OUT"] = release
  params["LIB"] = default_exporter_src + '/../lib/dcc-etl-exporter.jar'
  params["OBSERVATION"] = data_source + '/' + data[type] + part

  params["TMP_DYNAMIC_DIR"] = tmp_dynamic
  params["TMP_HFILE_DIR"] = tmp_hfile
  params["UPLOAD_TO_RELEASE"] = release
  params["DATATYPE"] = type

  try:
    loader
  except NameError:
    print "Use default JSON Loader"
  else:
    params["JSON_LOADER"] = loader

  SchemaUtil.createArchiveTable();
  SchemaUtil.createMetaTable(SchemaUtil.getMetaTableName(release));
  DynamicStorage.init(type, release);

  scriptDir = default_exporter_src + '/' + type
  Pig.set("pig.import.search.path", scriptDir);
  P = Pig.compileFromFile(type, scriptDir + '/dynamic.pig')

  bound = P.bind(params)
  stats = bound.runSingle()
  if not stats.isSuccessful():
    touch(logfile)
    print stats.getErrorMessage()
    raise 'failed'

  print 'Pig job succeeded'

def exportStaticData(type):
  out_static = root_out_static + "/" + release + "/Projects"
  out_summary = root_out_static + "/" + release + "/Summary"

  # create directory (if needed)
  Pig.fs("mkdir " + out_static)

  tmp_static = tmp_static_root + "/" + release + "/" + type + "/"

  # remove tmp directory
  Pig.fs("rm -r -skipTrash " + tmp_static)

  params["RELEASE_OUT"] = release
  params["LIB"] = default_exporter_src + '/../lib/dcc-etl-exporter.jar'
  params["OBSERVATION"] = data_source + '/' + data[type] + part

  params["TMP_STATIC_DIR"] = tmp_static
  params["OUT_STATIC_DIR"] = out_static

  params["DATATYPE"] = type
  params["STATIC_FILE_NAME_PREFIX"] = longname[type]

  try:
    loader
  except NameError:
    print "Use default JSON Loader"   
  else:
    params["JSON_LOADER"] = loader
  scriptDir = default_exporter_src + '/' + type
  Pig.set("pig.import.search.path", scriptDir);
  P = Pig.compileFromFile(type, scriptDir + '/static.pig')
  bound = P.bind(params)
  stats = bound.runSingle()
  if not stats.isSuccessful():
    touch(logfile)
    print stats.getErrorMessage()
    raise 'failed'

  # now we need to concatenate all files into 1
  StaticMultiStorage.concatenate(longname[type], tmp_static, out_static, '.gz')
  
  # now output summary files if applicable
  if summary[type]:
    StaticMultiStorage.concatenateAll(longname[type], tmp_static, out_summary, '.gz')
  
  print 'Pig job succeeded'
  
if __name__ == "__main__":
  try:
    opts, args = getopt.getopt(sys.argv[1:],"hsbd:i:e:r:u:l:",["type=","source=","exporter=","release="])
  except getopt.GetoptError:
    print 'exporter.py -d <data type separated by comma> [-i <data source directory>] [-e <pig script directory>] [-r <release>]'
    sys.exit(2)
    
  isStatic = False;
  isDynamic = False;
  logfile = "/tmp/exporter.ec"
  for opt, arg in opts:
    if opt == '-h':
      print 'exporter.py -d <data type separated by comma> [-i <data source directory>] [-e <pig script directory>] [-r <release>]' 
    elif opt in ("-d", "--type"):
      dataTypes = arg.split(',')
    elif opt in ("-i", "--source"):
      data_source = arg
    elif opt in ("-e", "--exporter"):
      default_exporter_src = arg
    elif opt in ("-r", "--release"):
      release = arg
    elif opt in ("-l", "--log"):
      logfile = arg
    elif opt == '-s':
      isStatic = True
    elif opt == '-b':
      isDynamic = True

  for type in dataTypes:
    if isStatic :
      exportStaticData(type)
    if isDynamic :
      exportDynamicData(type)

