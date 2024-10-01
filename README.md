
# RustDesk Web Client

Fork aiming to improve both **building process and features of the Web Client** of [RustDesk](https://github.com/rustdesk/rustdesk) (_An open-source remote desktop, and alternative to TeamViewer_).

## Branches

List and description of each branch of this repository, and associated modifications  
(_You can click branch's names to access them quickly_).

Any branch not described below is probably about something else "Work in Progress", or is a fix that will be turned into a Pull Request to the official RustDesk repo.

### [`master`/`fork`](https://github.com/MonsieurBiche/rustdesk-web-client/tree/master)

> Branch used to pull commits from the [official repository](https://github.com/rustdesk/rustdesk). Allows rebasing on RustDesk's modifications, regularly.

### [`fix-build`](https://github.com/MonsieurBiche/rustdesk-web-client/tree/fix-build)

> Enhanced Docker setup allowing to build and run RustDesk Web Client without issues.

#### TODO
- Improve that setup (for quicker build) and clean it (especially the messy Dockerfile)
- Add CI/CD to rebuild and push various images of the Web Client, for each released version
  - A regular version (no modifications, no wss)
  - A wss-only version (no modifications except wss)
  - A wss-feat version (modifications and wss)
- Make a customizable (using `ARGS` ?) build process, to allow adding custom server values

### [`enable-wss`](https://github.com/MonsieurBiche/rustdesk-web-client/tree/enable-wss)

> Small code modification to force RustDesk Web Client to establish `wss://` connections. **You will need to setup a Reverse Proxy correctly**, as RustDesk Server does not support WSS (see [rustdesk-server/issues/94](https://github.com/rustdesk/rustdesk-server/issues/94) & [rustdesk-server/issues/337](https://github.com/rustdesk/rustdesk-server/issues/337) )

#### TODO
- Rework and add schema from https://github.com/rustdesk/rustdesk/discussions/5145#discussioncomment-8346782 in docs
- Add traefik setup from https://github.com/rustdesk/rustdesk/discussions/6023#discussioncomment-8687562 in docs

### [`add-features`](https://github.com/MonsieurBiche/rustdesk-web-client/tree/add-features)

> Branch where all additionnal (and/or experimental) features are pushed.

#### List of modifications
- Auto connect/login using query parameters, based on [JelleBunning's fork](https://github.com/JelleBuning/rustdesk/tree/fix_build).
  > Allows using URLs like https://your.host.com/#/connect?id=123456789&pw=your-password

- Enforce `adaptive` scale (`ViewStyle`) when starting a remote connection, for a better behaviour.
- Small codes fixes on the `mobile` side of the code (`RemotePage` especially), to remove errors in browser's console.

#### TODO
- Fix issues around Web Client usage on a Mobile device (see [rustdesk/issues/7667](https://github.com/rustdesk/rustdesk/issues/7667))

## Contributing

Feel free to contribute, there's a lot of things to improve (as shown in TODOs), help, knowledge and new ideas are always welcome 😉