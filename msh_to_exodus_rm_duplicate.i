# created by write_txt_for_3D_fracture_mesher.py
# This is a MOOSE input file to remove duplicate elements from sidesets created by Andy's script
# Run it using:  falcon-opt -i msh_to_exodus_rm_duplicate.i mesh_size=20 --mesh-only Case_B_Fractures_Local_20m.e
mesh_size='20'
[Mesh]
  [fmg]
    type = FileMeshGenerator
    file = Case_B_Fractures_Local_${mesh_size}m.msh
  []
  [rename]
    type = RenameBlockGenerator
    input = fmg
    old_block = '2'
    new_block = '1000'
  []
  [rmDuplicateSS]
    type = RemoveDuplicateFacesFromSidesets
    input = rename
  []
  [fracture1]
    type = LowerDBlockFromSidesetGenerator
    input = rmDuplicateSS
    new_block_id = 1
    new_block_name = 'fracture1'
    sidesets = 'disk1'
  []
[]