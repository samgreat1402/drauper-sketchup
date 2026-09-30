# Run after creating two fresh Gabled Dormers on one fresh Draupr roof:
# load File.join(Draupr::ROOT,'qa','native_dormer_v340_audit.rb'); Draupr::QA::DormerV340.audit
module Draupr
  module QA
    module DormerV340
      module_function
      def audit
        roofs=Core::Objects.all.select { |g| Core::Metadata.read(g)['type']=='roof' }
        dormers=Core::Objects.all.select { |g| Core::Metadata.read(g)['type']=='dormer' }
        raise 'Expected exactly one test roof.' unless roofs.length==1
        roof=roofs.first;uid=Core::Objects.id(roof);openings=Core::Hosts.roof_holes(roof)
        raise 'Create at least two fresh Gabled Dormers.' unless dormers.length>=2
        raise 'Opening registry mismatch.' unless openings.length==dormers.length
        raise 'Roof persistent ID changed during recut.' unless roof.get_attribute('Draupr','entity_pid').to_i==roof.persistent_id
        raise 'A Dormer lost its host.' unless dormers.all? { |d| JSON.parse(d.get_attribute('Draupr','hosts_json','[]')).any? { |h| h['id']==uid } }
        raise 'A Dormer is not using the phase-1 contract.' unless dormers.all? { |d| Core::Objects.params(d)['dormer_type']=='gabled' }
        result={'release'=>'3.4.0 Preview','roof_uid'=>uid,'roof_pid'=>roof.persistent_id,'dormers'=>dormers.length,'openings'=>openings.length,'passed'=>true}
        puts JSON.pretty_generate(result);result
      end
    end
  end
end
