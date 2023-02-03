%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

// * -------------------------------------------------------------------------- * //
// *                                   Storage                                  * //
// * -------------------------------------------------------------------------- * //

@storage_var
func token0() -> (address: felt) {
}

@storage_var
func token1() -> (address: felt) {
}

// getPrice

// swap exact tokens for ETH