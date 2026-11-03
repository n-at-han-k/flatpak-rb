# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "flatpak"

describe Flatpak do
  it "defines the namespace from the typelib" do
    # Not an arbitrary number: it is the point of the loader. A hand-written
    # binding exposes what someone got round to wrapping; this exposes what
    # libflatpak has. Flatpak-1.0.typelib yields about thirty constants, so a
    # drop to single digits means the loader half-ran.
    expect(Flatpak.constants.size).to be > 20
  end

  it "defines the classes a caller actually reaches for" do
    expect(Flatpak.const_defined?(:Installation)).to be == true
    expect(Flatpak.const_defined?(:Remote)).to be == true
    expect(Flatpak.const_defined?(:Ref)).to be == true
    expect(Flatpak.const_defined?(:InstalledRef)).to be == true
    expect(Flatpak.const_defined?(:Transaction)).to be == true
  end

  it "defines the enumerations too, not only the classes" do
    # These are GEnum/GFlags rather than GObject types, and the loader walks
    # them by a different path, so they fail separately from the classes.
    expect(Flatpak.const_defined?(:RefKind)).to be == true
    expect(Flatpak.const_defined?(:StorageType)).to be == true
    expect(Flatpak.const_defined?(:InstallFlags)).to be == true
  end

  it "maps GObject methods onto the class, not just constants" do
    # A loader that registered the types but no methods would still satisfy
    # every assertion above, so this is the one that catches a half-loaded
    # namespace. Installation carries about eighty methods of its own.
    expect((Flatpak::Installation.instance_methods - Object.instance_methods).size).to be > 20
    expect((Flatpak::Remote.instance_methods - Object.instance_methods).size).to be > 20
  end

  it "loads classes that descend from GObject" do
    # What the loader produces should be GLib::Object subclasses rather than
    # bare Ruby classes -- that is the difference between a registered GType
    # and an empty shell named after one.
    expect(Flatpak::Installation.ancestors).to be(:include?, GLib::Object)
    expect(Flatpak::Remote.ancestors).to be(:include?, GLib::Object)
  end

  it "constructs a remote and reads back what it was given" do
    # Needs neither a main loop, a display, root, nor a configured
    # installation on the machine: FlatpakRemote is a plain GObject until it
    # is handed to an installation.
    remote = Flatpak::Remote.new("test-remote")

    expect(remote).to be_a(Flatpak::Remote)
    expect(remote.name).to be == "test-remote"
  end

  it "round-trips a GObject property" do
    remote = Flatpak::Remote.new("test-remote")
    remote.url = "https://example.com/repo/"

    expect(remote.url).to be == "https://example.com/repo/"
  end

  it "calls the namespace's module functions" do
    # Module-level functions land as singleton methods on Flatpak, which is a
    # third path through the loader again.
    expect(Flatpak.default_arch).to be_a(String)
    expect(Flatpak.supported_arches).to be(:include?, Flatpak.default_arch)
  end
end
