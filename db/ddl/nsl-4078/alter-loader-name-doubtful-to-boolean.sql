alter table loader_name alter column doubtful
set data type boolean
using case
  when doubtful = '0' then false
  when doubtful = '1' then true
  else false
end;
