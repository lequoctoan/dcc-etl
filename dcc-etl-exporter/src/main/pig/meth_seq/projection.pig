-- Copyright (c) 2016 The Ontario Institute for Cancer Research. All rights reserved.
--
-- This program and the accompanying materials are made available under the terms of the GNU Public License v3.0.
-- You should have received a copy of the GNU General Public License along with
-- this program. If not, see <http://www.gnu.org/licenses/>.
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
-- EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
-- SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
-- INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
-- TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
-- OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
-- IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
-- ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

%default JSON_LOADER 'com.twitter.elephantbird.pig.load.JsonLoader';
%default OBSERVATION '<observation_files>';

DEFINE ExtractId org.icgc.dcc.etl.exporter.pig.udf.ExtractId();

-- load observation
observation = LOAD '$OBSERVATION' USING $JSON_LOADER('-nestedLoad') as document:map[];

meth = FILTER observation BY document#'_type' == '$DATATYPE';
selected_meth = foreach meth generate ExtractId(document#'_donor_id') as donor_id:int,
				      document#'_donor_id' as icgc_donor_id,
                                      document#'_project_id' as project_code,
                                      document#'_specimen_id' as icgc_specimen_id,
                                      document#'_sample_id' as icgc_sample_id,
                                      document#'analyzed_sample_id' as submitted_sample_id, 
                                      document#'analysis_id' as analysis_id,
                                      document#'chromosome' as chromosome,
                                      document#'chromosome_start' as chromosome_start,
                                      document#'chromosome_end' as chromosome_end,
                                      document#'chromosome_strand' as chromosome_strand,
                                      document#'assembly_version' as assembly_version,
                                      document#'methylation_ratio' as methylation_ratio,
                                      document#'methylated_read_count' as methylated_read_count,
                                      document#'unmethylated_read_count' as unmethylated_read_count,
                                      document#'verification_status' as verification_status,
                                      document#'verification_platform' as verification_platform,
                                      document#'sequencing_platform' as sequencing_platform,
                                      document#'fraction_wg_cpg_sites_covered' as fraction_wg_cpg_sites_covered,
                                      document#'conversion_rate' as conversion_rate,
                                      document#'experimental_protocol' as experimental_protocol,
                                      document#'sequencing_strategy' as sequencing_strategy,
                                      document#'base_quality_score_threshold' as base_quality_score_threshold,
                                      document#'alignment_algorithm' as alignment_algorithm,
                                      document#'other_analysis_algorithm' as other_analysis_algorithm,
                                      document#'raw_data_repository' as raw_data_repository,
                                      document#'raw_data_accession' as raw_data_accession;
