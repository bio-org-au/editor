module Loader::Name::MakeOneInstance::MakeOneStandaloneInstance::CopyAndAppend::Constants
  CREATED = [1,0,0]
  DECLINED = [0,1,0]
  ERROR = [0,0,1]
  phrase = " standalone instance using default ref (copy-and-append)"
  DECLINED_INSTANCE = "<span class='firebrick'>Declined to make#{phrase}</span>"
  CREATED_INSTANCE = "<span class='darkgreen'>Made#{phrase} </span>"
  FAILED_INSTANCE = "<span class='red'>Failed to make#{phrase} </span>"

  syn_phrase = " copy-and-append synonymy instance "
  FAILED_SYN = "<span class='red'>Failed to make#{syn_phrase} </span>"
  DECLINED_SYN = "<span class='firebrick'>Declined to make#{syn_phrase}</span>"
  CREATED_SYN = "<span class='darkgreen'>Made#{syn_phrase} </span>"

  copy_syn_phrase = " copy of synonym "
  COPIED_SYN = "<span class='darkgreen'>Made#{copy_syn_phrase} </span>"
end

