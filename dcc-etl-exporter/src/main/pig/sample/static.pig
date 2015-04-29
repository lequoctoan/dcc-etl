%default LIB 'lib/dcc-etl-exporter.jar'
REGISTER $LIB

%default DATATYPE 'sample'
%default STATIC_FILE_NAME_PREFIX '<from-param>'

set job.name static-$DATATYPE;

%default RELEASE_OUT 'r12';
%default TMP_STATIC_DIR    '<tmp_static_dir>'
%default OUT_STATIC_DIR    '<tmp_dynamic_dir>'

%default DEFAULT_PARALLEL '3';
set default_parallel $DEFAULT_PARALLEL;

%default EMPTY_VALUE '';
%declare EMPTY_SPECIMEN ['_specimen_id'#'$EMPTY_VALUE','specimen_id'#'$EMPTY_VALUE']
%declare EMPTY_SAMPLE ['_sample_id'#'$EMPTY_VALUE','analyzed_sample_id'#'$EMPTY_VALUE','analyzed_sample_interval'#'$EMPTY_VALUE']

-- load donor 
import 'projection.pig';

content = FOREACH selected_donor 
          GENERATE project_code, 
                   icgc_donor_id,
                   FLATTEN(((specimens is null or IsEmpty(specimens)) ? {($EMPTY_SPECIMEN)} : specimens)) as specimen;

content = FOREACH content 
          GENERATE project_code, 
                   specimen#'_specimen_id' as icgc_specimen_id, 
                   icgc_donor_id,
                   specimen#'specimen_id' as submitted_specimen_id, 
                   FLATTEN((bag{tuple(map[])}) specimen#'sample') as s;

static_out = FOREACH content 
             GENERATE s#'_sample_id' as icgc_sample_id,
                      project_code,
                      icgc_specimen_id, 
                      icgc_donor_id,
                      s#'analyzed_sample_id' as submitted_sample_id,
                      submitted_specimen_id,
                      s#'percentage_cellularity' as percentage_cellularity,
                      s#'level_of_cellularity' as level_of_cellularity,
                      s#'study' as study;

STORE static_out INTO '$TMP_STATIC_DIR' USING org.icgc.dcc.etl.exporter.pig.storage.StaticMultiStorage('$TMP_STATIC_DIR', '$STATIC_FILE_NAME_PREFIX', 'project_code', 'gz', '\\t');
