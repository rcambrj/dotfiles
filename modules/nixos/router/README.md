# Router

This is the bulk of the code which brings up `hosts/cloudberry`. This code is somewhat modular and reusable, but the main purpose is so that I could write tests. That is, `hosts/cloudberry/router.nix` brings up this router with its own configuration and so does `packages/router-test/router.nix`.

I suggest caution while consuming this module directly in your own configuration, because I make no guarantees regarding breaking changes and haven't really documented anything.

Instead, copy + paste or take inspiration.