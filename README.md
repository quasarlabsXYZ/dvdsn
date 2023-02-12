<h1 id="readme-title" align="center">
    <img src="./assets/StarkNet-Icon.png" width="200"/>
    <br>
    Damn Vulnerable DeFi Starknet
</h1>

<h4 id="readme-description" align="center">
    A playground to learn offensive security of DeFi smart contracts on Starknet, inspired by <a href="https://www.damnvulnerabledefi.xyz/">Damn Vulnerable DeFi</a>
</h4>

## Note
- **DVDSN is a project started at the TVL Hackers Building (Feb 2023) and still under active development, any contribution welcome!**

## Challenges

| #    | Name                                    |
| :--- | :-------------------------------------- |
| 1    | [Unstoppable](docs/Unstoppable.md)      |
| 2    | [Naive Receiver](docs/NaiveReceiver.md) |
| 3    | [Truster](docs/Truster.md)              |
| 4    | [Side Entrance](docs/SideEntrance.md)   |
| 5    | [Logic Delegate](docs/LogicDelegate.md) |
| 6    | [The Rewarder](docs/TheRewarder.md) |


## Hacking

1. Set up [protostar](https://github.com/software-mansion/protostar)
2. Clone this [repository](https://github.com/quasarlabsXYZ/dvdsn)
3. Install dependencies with `protostar install`
4. Hack and run `protostar test challenges/[challenge-name]/test_[challenge-name].challenge.cairo`

## Contributing

PRs are welcomed!

1. Set up [protostar](https://github.com/software-mansion/protostar)
2. Fork this [repository](https://github.com/quasarlabsXYZ/dvdsn)
3. Install dependencies with `protostar install`
4. Create challenge in separated folders under [`src/`](src/) and solving framework under [`challenges/`](challenges/)
5. Add challenge statement under [`docs/`](docs/) and update [`README.md`](README.md)

## Reference

Credit to [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)

## License

[MIT © 2023](LICENSE)
