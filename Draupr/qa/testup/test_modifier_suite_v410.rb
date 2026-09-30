# frozen_string_literal: true
require 'testup/testcase'
class DrauprModifierSuiteTest < TestUp::TestCase
  def test_supported_path_kinds
    expected=%w[wall curtain_wall beam railing louver molding foundation]
    assert_equal(expected,Draupr::Core::ModifyTools::PATH_KINDS)
  end
  def test_nine_point_profile_registration
    points=[[0.0,0.0],[1.0,0.0],[1.0,1.0],[0.0,1.0]]
    assert_equal([0.5,0.5],Draupr::Core::MoldingProfiles.anchor(points,'center'))
    assert_equal([1.0,0.0],Draupr::Core::MoldingProfiles.anchor(points,'right_bottom'))
  end
  def test_boundary_plane_height
    plane=[0.0,0.0,1.0,-120.0]
    assert_in_delta(120.0,Draupr::Core::ModifyTools.plane_height(plane,ORIGIN),0.001)
  end
end
