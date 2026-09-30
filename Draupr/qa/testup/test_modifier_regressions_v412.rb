# frozen_string_literal: true
require 'testup/testcase'
class DrauprModifierRegressionsV412Test < TestUp::TestCase
  def test_roof_envelope_selects_containing_slope
    left={'plane'=>[0.0,0.5,1.0,-100.0],'polygon'=>[[0,0,0],[100,0,0],[100,100,0],[0,100,0]]}
    right={'plane'=>[0.0,-0.5,1.0,-100.0],'polygon'=>[[0,100,0],[100,100,0],[100,200,0],[0,200,0]]}
    record={'surfaces'=>[left,right]}
    assert_in_delta(75.0,Draupr::Core::Walls.boundary_z(record,Geom::Point3d.new(50,50,0),0),0.001)
    assert_in_delta(175.0,Draupr::Core::Walls.boundary_z(record,Geom::Point3d.new(50,150,0),0),0.001)
  end
  def test_knife_redistributes_segment_overrides
    source={'0'=>10.0,'1'=>20.0,'2'=>30.0}
    assert_equal({'0'=>10.0,'1'=>20.0},Draupr::Core::ModifyTools.split_indexed_values(source,1,:first))
    assert_equal({'0'=>20.0,'1'=>30.0},Draupr::Core::ModifyTools.split_indexed_values(source,1,:second))
  end
end
