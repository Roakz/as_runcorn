require_relative '../common/qsa_id'
require_relative '../common/search_utils'
require_relative '../common/date_range_query'

# QSADAP-168 We don't want to index URIs as they contain database IDs that
# pollute search results.
IndexerCommon::EXCLUDED_STRING_VALUE_PROPERTIES << 'uri'
IndexerCommon::EXCLUDED_STRING_VALUE_PROPERTIES << 'ref'
