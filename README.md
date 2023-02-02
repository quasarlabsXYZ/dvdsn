<h1 align="center">
    <img src="./assets/StarkNet-Icon.png" width="200"/>
    <br>
    Damn Vulnerable DeFi Starknet
</h1>

<h4 align="center">
    A playground to learn offensive security of DeFi smart contracts on Starknet, inspired by <a href="https://www.damnvulnerabledefi.xyz/">Damn Vulnerable DeFi</a>
</h4>

## Note
- **DVDSN is a project starts at the TVL Hackers Building (Feb 2023) and still under active development, any contribution is welcomed!**
- **Please feel free to reach out to [@dcfpascal](https://t.me/dcfpascal) or [@kootsZhin](https://t.me/kootsZhin) on Telegram if you have any question.**

## Challenges

| #    | Name                               |
| :--- | :--------------------------------- |
| 1    | [Placeholder](docs/Placeholder.md) |

## Hacking

1. Set up [protostar](https://github.com/software-mansion/protostar)
2. Clone this [repository](https://github.com/quasarlabsXYZ/dvdsn)
3. Install dependencies with `protostar install`
4. Hack and run `protostar test tests/[challenge-name]/test_[challenge-name].challenge.cairo`

## Contributing

PRs are welcomed!

1. Set up [protostar](https://github.com/software-mansion/protostar)
2. Fork this [repository](https://github.com/quasarlabsXYZ/dvdsn)
3. Install dependencies with `protostar install`
4. Create challenge in separated folders under [`src/`](src/) and solving framework under [`tests/`](tests/)
5. Add challenge statement under [`docs/`](docs/) and update [`README.md`](README.md)

## Reference

1. [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/)
2. [Amarna: Static analysis for Cairo programs](https://blog.trailofbits.com/2022/04/20/amarna-static-analysis-for-cairo-programs/)
3. [How to hack (almost) any Starknet Cairo smart contract](https://medium.com/ginger-security/how-to-hack-almost-any-starknet-cairo-smart-contract-67b4681ac0f6)

## License

[MIT © 2023](LICENSE)
