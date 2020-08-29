# Ephemeros

Tools and configuration for provisioning OS diskless Container Linux clusters,
running [k3s](https://k3s.io) and logging with
[Papertrail](https://papertrail.com). Nodes boot from an iPXE flash drive,
which also contains a dedicated volume for keeping secrets.

The iPXE script downloads and boots the newest stable release for Flatcar
Container Linux (RIP CoreOS), which then pulls in the
[ignition.ign](ignition.ign) file in this repo.

Since that is publicly visible, we cannot have any secrets kicking around in
there. But we still need those values to be carried over somehow, so we capture
those values at iPXE flash drive provisioning-time and throw them into the
`secrets` volume. From there, all service definitions pull what they need from
`/secrets`, which is readonly mounted.

## Making boot media

Pop in a flash drive you don't care about and then run the following:

```shell
sudo \
    SSH_KEY_PATH=$HOME/.ssh/id_rsa.pub \
    NODE_HOSTNAME=node1337 \
    PAPERTRAIL_HOST=logsX.papertrailapp.com PAPERTRAIL_PORT=XXXXX \
    UPTIMEROBOT_HEARTBEAT_PATH=biglongopaquethingitgivesyou \
    K3S_DATASTORE_ENDPOINT="see the k3s docs" \
    # Other K3S_* env vars you probably want to set \
    ./build_pxe_stick.sh /dev/sdX
```

If you don't specify expected `PAPERTRAIL_*`, `UPTIMEROBOT_*` or `K3S_*`, we'll
throw up a warning in `build_pxe_stick.sh` and those components won't be
activated at system runtime.

### What values should be used?

#### `NODE_HOSTNAME`

The bare hostname you want to set for the node, e.g. `node0`. If you don't set
this, we won't do anything special to automatically set the hostname. 

#### `SSH_KEY_PATH`

Path to a SSH public key, e.g. `$HOME/.ssh/id_rsa.pub` (the default). We need
this to be something, as otherwise we're entirely the values set when the
Ignition config is applied

#### `PAPERTRAIL_HOST` and `PAPERTRAIL_PORT`

These values are ripped from the [Papertrail setup page](
https://papertrailapp.com/systems/setup?type=system&platform=unix). See the bit
at the top that says "Your logs will go to...". These values seem to be scoped
to the Papertrail account, rather than an individual sender, so feel free to
reuse those values across multiple nodes.

#### `UPTIMEROBOT_HEARTBEAT_PATH`

UptimeRobot supports multiple types of monitoring signals. Some of these
signals are free, but not heartbeat. :(

Unlike with Papertrail, you need dedicated values for each host here. To get
those, you'll want to:

1.  head to the [UptimeRobot dashboard](
    https://uptimerobot.com/dashboard#mainDashboard)
2.  click `+ Add New Monitor` at the top left (sorry, can't link it)
3.  select monitor type -> "Heartbeat (Beta)" (it's in beta at the time of
    writing)
4.  set the "Friendly Name" to the node's hostname
5.  set a monitoring inverval of "every 5 minutes"

That'll kick out a URL like `https://heartbeat.uptimerobot.com/BUNCH_OF_CHARS`.
Grab that bunch of chars and that's the value for `UPTIMEROBOT_HEARTBEAT_PATH`.

TODO(mcsaucy): change our logic to take a whole URL so this is easier.

#### `K3S_DATASTORE_ENDPOINT`

See [k3s docs](https://rancher.com/docs/k3s/latest/en/installation/datastore/)
for more details here. If you want to use the embedded SQLite option, set this
to an empty value explicitly.

#### Other `K3S_` vars

Just add em in and we'll preserve em. `k3s` will start with those vars set.

## Updating the Ignition configs

The [ignition.ign](ignition.ign) file is generated from the
[ignition.yml](ignition.yml) file. You can perform that tranformation with
the following:

```shell
bash ./ignite.sh ignition.yml > ignition.ign
```

Note that the ignition config is pulled down from github each boot, so you'll
need to push any changes in order to test them. There's likely some room here
for certain iPXE values (such as the ignition config URI) to be derived from
the git repo itself...

## Testing with qemu

You can have qemu boot the flash drive for testing purposes. Note that this
will result in downloading several hundred megabytes each run. To do this use:
`./qemu_test /dev/sdX`. If you get stuck in the console, then `alt-2` and then
`quit` should get you out. You can also run it with `NO_CURSES=1` environment
variable set if you want your console in a dedicated graphical window rather
than a terminal:

```shell
NO_CURSES=1 ./qemu_test /dev/sdX
```

Then you can just `ssh core@localhost -p 2222` when it's done booting.

## I wanna mess with this

Cool! You're probably gonna wanna call `build_pxe_stick.sh` with a custom
`IGN_PATH`. The default is
`https://raw.githubusercontent.com/mcsaucy/ephemeros/master/ignition.ign`, so
you'll probably want to change that to the URI for your own.
