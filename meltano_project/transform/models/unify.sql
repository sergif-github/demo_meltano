select name, email
from {{ source('tap_postgres', 'users') }}

union

select name, email
from {{ source('tap_rest_api_msdk', 'users') }}
