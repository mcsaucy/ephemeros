# Ephemeros

Tools and configuration for provisioning OS diskless Container Linux clusters,
running [k3s](https://k3s.io) and logging with
[Papertrail](https://papertrail.com). Nodes boot from an iPXE flash drive,
which also contains a dedicated volume for keeping secrets. *Apply platform
config changes and updates by rebooting.*

The iPXE script downloads and boots the newest stable release for Flatcar
Container Linux (RIP CoreOS), which then pulls in the
[ignition.ign](ignition.ign) file in this repo.

Since that is publicly visible, we cannot have any secrets kicking around in
there. But we still need those values to be carried over somehow, so we capture
those values at iPXE flash drive provisioning-time and throw them into the
`secrets` volume. From there, all service definitions pull what they need from
`/secrets`, which is readonly mounted.

## Why?

A number of reasons, in no particular order:

- I didn't want boot drives stealing SATA ports and drive bays on my machines
- I didn't want another computing environment that turned into me managing a
  small pack of Debian/Fedora boxes
- I didn't want to shell out additional money for OS drives that would
  basically just hold logs
- I didn't want to manage a bunch of infrastructure (log collection, config
  management, presence monitoring) just to have a basic, reliable deployment
- I *did* want to try something new

### What could a possible deployment look like?

You can swing a decent deployment using hosted services to the tune of less
than $20/month. These are just the bare necessities to bootstrap and monitor a
k3s cluster. For any actual applications, you may want dedicated storage. A
way to accomplish that would be with a [Rook](https://rook.io)-managed [Ceph](
https://ceph.io) cluster (backed by local disks, probably), which is then
either used by external clients or cluster-internal containers.

#### Log collection
papertrail.com has a free tier with 48 hours of search and 7 days of archives.

#### k3s datastore hosting
Heroku's "Hobby Basic" tier of hosted postgres allows for 10 million rows at
$9/month. My "this is a single node doing nothing" test hit 3k rows, so
10 million rows will hopefully be enough headroom. Worst case, the next tier
$50/month, which will be high enough for me to consider what I want to do
longer term.

#### Hearbeat monitoring
You can get some super basic (but functional) heartbeat monitoring with
UptimeRobot. Unfortunately, heartbeat monitoring is a beta offering and not
free, but it's like $8/month so /shrug.

## Making boot media

Pop in a flash drive you don't care about and then run the following:

```shell
sudo \
    SSH_KEY_PATH=$HOME/.ssh/id_rsa.pub \
    NODE_HOSTNAME=node1337 \
    LOGEXPORT_HOST=logsX.papertrailapp.com LOGEXPORT_PORT=XXXXX \
    HEARTBEAT_URL=https://nudge.me/im_alive \
    K3S_DATASTORE_ENDPOINT="see the k3s docs" \
    # Other K3S_* env vars you probably want to set \
    ./build_pxe_stick.sh /dev/sdX
```

If you don't specify expected `LOGEXPORT_*`, `HEARTBEAT_*` or `K3S_*`, we'll
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

#### `LOGEXPORT_HOST` and `LOGEXPORT_PORT`

Where you get these values will vary a lot based upon which log ingestion
service you use. We support the "just pipe `journalctl -f` to `ncat`" approach
that's used by Papertrail (and maybe others? idk).

##### Using Papertrail

If you're using Papertrial, you can rip these from from the
[Papertrail setup page](
https://papertrailapp.com/systems/setup?type=system&platform=unix). See the bit
at the top that says "Your logs will go to...". These values seem to be scoped
to the Papertrail account, rather than an individual sender, so feel free to
reuse those values across multiple nodes.

#### `HEARTBEAT_URL`

This can really be any URL; we're just gonna call it every 5 minutes with
`wget --spider`. It wouldn't be rocket surgery to implement your own heartbeat
monitor service, but there are services that offer this.

##### Using healthchecks.io

Unlike with Papertrail, you need dedicated values for each host here. At the
time of writing, healthchecks.io offers a free hobby tier with up to 20 checks.
To get the host's `HEARTBEAT_URL`, you'll want to:

1.  head to the [healthchecks.io dashboard](https://healthchecks.io).
2.  sign in (if necessary) and select a project
3.  click `Add Check` at the bottom
4.  hit the small `edit` link at the top by the auto-generated UUID title to
    set a better title
5.  find the `Change Schedule...` button in the `Schedule` section near the
    bottom of the page
6.  set the period to 5 minutes and the grace time to 1 minute
7.  configure notifications in the "Notification Methods" section
8.  grab the `hc-ping.com` URL from the "How To Ping" section, and that's your
    `HEARTBEAT_URL` value

##### Using UptimeRobot Heartbeat signals

Unlike with Papertrail, you need dedicated values for each host here. To get
those, you'll want to:

1.  head to the [UptimeRobot dashboard](
    https://uptimerobot.com/dashboard#mainDashboard)
2.  click `+ Add New Monitor` at the top left (sorry, can't link it)
3.  select monitor type -> "Heartbeat (Beta)" (it's in beta at the time of
    writing)
4.  set the "Friendly Name" to the node's hostname
5.  set a monitoring inverval of "every 5 minutes"
6.  work out who should be alerted when things break

That'll kick out a URL like `https://heartbeat.uptimerobot.com/BUNCH_OF_CHARS`.
That's the value for `HEARTBEAT_URL`.

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
