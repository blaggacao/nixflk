{ self, ... }:
let
  bud = self.inputs.bud self;
in
{
  modules = [
    (import ./devos bud)
  ];
}
