# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "gobject-introspection"

require_relative "flatpak/version"
require_relative "flatpak/loader"

# Ruby bindings for libflatpak, querying and managing Flatpak installations.
#
# Nothing here wraps a C function by hand. The library ships a GObject
# Introspection typelib describing every class, method, property and signal it
# has, and ruby-gnome's GObjectIntrospection::Loader reads that at require time
# and defines the Ruby classes from it. {Flatpak::Loader} is about twenty lines;
# what you get is the whole library, and it does not drift when the library
# gains API.
#
# This is how ruby-gnome itself ships gtksourceview5, libsecret and the rest.
#
# The typelib has to be findable at require time, which means the library's
# `girepository-1.0` directory on `GI_TYPELIB_PATH` or in the system default.
# This gem cannot install it -- it is a C library artefact and belongs to the
# distribution. See the README for the package name; `flake.nix` wires up a dev
# shell that has it.
#
# One trap, paid for already: the typelib must come from the same glib build as
# the `gobject-introspection` gem. Mix two and GIO is registered twice in one
# process, which fails as `cannot register existing type 'GTlsCertificate'`.
module Flatpak
  LOG_DOMAIN = "Flatpak"
  GLib::Log.set_log_domain(LOG_DOMAIN)

  class Error < StandardError
  end

  loader = Loader.new(self)
  loader.load
end
