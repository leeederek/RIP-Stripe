// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/libraries/OrbitalCoreMath.sol";

contract MathDebugTest is Test {
    using OrbitalCoreMath for uint256;
    
    function test_SqrtCalculation() public {
        uint256 PRECISION = 1e18;
        
        // Test sqrt for n=2
        uint256 n2 = 2;
        uint256 input2 = n2 * PRECISION;
        uint256 sqrtN2 = OrbitalCoreMath.sqrt(input2);
        console.log("sqrt(2 * 1e18) =", sqrtN2);
        if (sqrtN2 > PRECISION) {
            console.log("sqrtN - PRECISION =", sqrtN2 - PRECISION);
        } else {
            console.log("sqrtN < PRECISION, diff =", PRECISION - sqrtN2);
        }
        
        // Test sqrt for n=4
        uint256 n4 = 4;
        uint256 input4 = n4 * PRECISION;
        uint256 sqrtN4 = OrbitalCoreMath.sqrt(input4);
        console.log("sqrt(4 * 1e18) =", sqrtN4);
        if (sqrtN4 > PRECISION) {
            console.log("sqrtN - PRECISION =", sqrtN4 - PRECISION);
        } else {
            console.log("sqrtN < PRECISION, diff =", PRECISION - sqrtN4);
        }
        
        // Test radius calculation
        uint256 perToken = 1000 * 1e18;
        if (sqrtN2 > PRECISION) {
            uint256 radius2 = perToken * sqrtN2 / (sqrtN2 - PRECISION);
            console.log("radius for n=2, perToken=1000e18:", radius2);
        }
    }
}