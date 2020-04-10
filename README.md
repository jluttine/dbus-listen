# dbus-listen

Execute a command or a script on selected D-Bus signals.

## Usage

```
dbus-listen - execute a command on D-Bus signals

Usage: dbus-listen [--session | --system | --starter | --address ADDRESS]
                   [--sender SEND] [--destination DEST] [--path PATH]
                   [--path-namespace NSPATH] [--interface IFACE]
                   [--member MEMBER] [-v|--verbose] CMD
  dbus-listen executes CMD on selected D-Bus signals

Available options:
  --session                Connect to the bus specified in the environment
                           variable DBUS_SESSION_BUS_ADDRESS (this is the
                           default behavior)
  --system                 Connect to the bus specified in the environment
                           variable DBUS_SYSTEM_BUS_ADDRESS, or to
                           unix:path=/var/run/dbus/system_bus_socket if
                           DBUS_SYSTEM_BUS_ADDRESS is not set
  --starter                Connect to the bus specified in the environment
                           variable DBUS_STARTER_ADDRESS
  --address ADDRESS        Connect to the bus at the specified address ADDRESS
  --sender SEND            If set, only receives signals sent from the given bus
                           name
  --destination DEST       If set, only receives signals sent to the given bus
                           name
  --path PATH              If set, only receives signals sent with the given
                           path
  --path-namespace NSPATH  If set, only receives signals sent with the given
                           path or any of its children
  --interface IFACE        If set, only receives signals sent with the given
                           interface name
  --member MEMBER          If set, only receives signals sent with the given
                           member name
  -v,--verbose             Enable verbose mode
  -h,--help                Show this help text

```


## Examples

### D-Bus monitor

To just monitor D-Bus signals one can use `--verbose` flag and give no-op `:` as
the executed command. For instance, to monitor all system D-Bus signals:

```
dbus-listen --verbose --system :
```


## Building

### Cabal

```
cabal build
```

### Nix


```
nix-build
```

The resulting executable is in `result/bin/dbus-listen`. To get a nix shell with
the dependencies:

```
nix-shell
```
