{
  makeScopeWithSplicing',
  generateSplicesForMkScope,
  attributePathToSplice ? [ "cygwin" ],
}:

let
  otherSplices = generateSplicesForMkScope attributePathToSplice;
in
makeScopeWithSplicing' {
  inherit otherSplices;
  f =
    self:
    let
      callPackage = self.callPackage;
    in
    {
    };
}
