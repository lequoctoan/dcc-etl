%default LIB 'udf/dcc-etl-exporter.jar'
REGISTER $LIB

%default DATATYPE 'exp_seq'

set job.name dynamic-$DATATYPE;

%default UPLOAD_TO_RELEASE '';
%default TMP_DYNAMIC_DIR   '<tmp_dynamic_dir>'
%default TMP_HFILE_DIR     '<tmp_hfile_dir>'
%default COMPRESSION_ENABLED 'true'

DEFINE COMPUTE_SIZE org.icgc.dcc.etl.exporter.pig.udf.ComputeSize();
DEFINE COMPOSITE_KEY org.icgc.dcc.etl.exporter.pig.udf.CompositeKey('$DATATYPE', '$UPLOAD_TO_RELEASE', '500000');
DEFINE DYNAMIC_STORAGE org.icgc.dcc.etl.exporter.pig.storage.DynamicStorage('$DATATYPE', '$UPLOAD_TO_RELEASE', '$COMPRESSION_ENABLED');
DEFINE STATISTIC_STORAGE org.icgc.dcc.etl.exporter.pig.storage.StatisticStorage('$DATATYPE', '$UPLOAD_TO_RELEASE');

%default DEFAULT_PARALLEL '3';
set default_parallel $DEFAULT_PARALLEL;

import 'projection.pig';

selected_content = FOREACH selected_exp GENERATE donor_id,
                                                 COMPOSITE_KEY(donor_id) as rowkey:bytearray,
                                                 icgc_donor_id..reference_sample_type;

obj = FOREACH selected_content GENERATE rowkey, {(icgc_donor_id..reference_sample_type)};
content = ORDER obj BY rowkey ASC PARALLEL $DEFAULT_PARALLEL;
STORE content INTO '$TMP_HFILE_DIR' USING DYNAMIC_STORAGE();

-- populate statistics
row_size = FOREACH selected_content GENERATE donor_id, COMPUTE_SIZE(icgc_donor_id..reference_sample_type) as bytes:long;
row_size_per_donor = GROUP row_size BY donor_id;
stats = FOREACH row_size_per_donor GENERATE group as donor_id, COUNT(row_size.donor_id) as total_line, SUM(row_size.bytes) as total_size;
STORE stats INTO '$TMP_DYNAMIC_DIR' USING STATISTIC_STORAGE();