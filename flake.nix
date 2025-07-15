{
  description = "My Collection of Nix Flake Templates";

  outputs =
    { self, ... }:
    {
      templates = {
        base = {
          path = ./templates/base;
          description = "A base template.";
        };
        bun = {
          path = ./templates/bun;
          description = "Bun template.";
        };

        defaultTemplate = self.templates.base;
      };
    };
}
