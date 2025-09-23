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
      w32api-headers = callPackage ./w32api/headers.nix { };

      newlib-cygwin-headers = callPackage ./newlib-cygwin/headers.nix { };
    };
}
