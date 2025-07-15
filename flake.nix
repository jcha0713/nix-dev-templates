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
        node = {
          path = ./templates/node;
          description = "Node template.";
        };
        gleam = {
          path = ./templates/gleam;
          description = "Gleam template";
        };

        defaultTemplate = self.templates.base;
      };
    };
}
