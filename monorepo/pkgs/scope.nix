{
  generateSplicesForMkScope,
  makeScopeWithSplicing',
  scopeName,
}:
makeScopeWithSplicing' {
  otherSplices = generateSplicesForMkScope "${scopeName}Packages";
  extra = self: { };
  f = self: {
    callPackage' = pkg: attrs: (self.callPackage pkg attrs) // { "${scopeName}Package" = true; };

    # example:
    # some-package = self.callPackage' ./my-package {};
  };
}
