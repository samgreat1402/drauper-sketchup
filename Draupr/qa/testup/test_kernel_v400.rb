# frozen_string_literal: true
# Run inside SketchUp with TestUp installed; this file is not loaded by Draupr.
require 'testup/testcase'
class DrauprKernelTest < TestUp::TestCase
  def test_grid_labels_continue_after_z
    assert_equal('Z',Draupr::Core::Builders.grid_label(25))
    assert_equal('AA',Draupr::Core::Builders.grid_label(26))
    assert_equal('AZ',Draupr::Core::Builders.grid_label(51))
  end
  def test_path_clean_rejects_coincident_points
    assert_raises(RuntimeError) { Draupr::Core::PathFrames.clean([ORIGIN,ORIGIN],false) }
  end
  def test_object_library_rejects_bad_checksum
    data={'bodies'=>[],'draupr_items'=>[],'geometry'=>{'checksum_sha256'=>'bad'}}
    assert_raises(RuntimeError) { Draupr::Core::LibraryService.validate_item!(data) }
  end
end
