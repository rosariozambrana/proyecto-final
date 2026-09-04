package com.cicd.webapi;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

public class CalculatorAdvTest {
    @Test
    void testSquare() {
        CalculatorAdv calc = new CalculatorAdv();
        assertEquals(25.0, calc.square(5), 0.001);
        assertEquals(0.0, calc.square(0), 0.001);
        assertEquals(9.0, calc.square(-3), 0.001);
    }

    @Test
    void testPower() {
        CalculatorAdv calc = new CalculatorAdv();
        assertEquals(8.0, calc.power(2, 3), 0.001);
        assertEquals(1.0, calc.power(5, 0), 0.001);
        assertEquals(16.0, calc.power(4, 2), 0.001);
    }

    @Test
    void testSquareRoot() {
        CalculatorAdv calc = new CalculatorAdv();
        assertEquals(5.0, calc.squareRoot(25), 0.001);
        assertEquals(0.0, calc.squareRoot(0), 0.001);
    }

    @Test
    void testSquareRootNegative() {
        CalculatorAdv calc = new CalculatorAdv();
        IllegalArgumentException ex = assertThrows(
            IllegalArgumentException.class,
            () -> calc.squareRoot(-9)
        );
        assertEquals("No se puede calcular raíz de número negativo", ex.getMessage());
    }

    @Test
    void testModulus() {
        CalculatorAdv calc = new CalculatorAdv();
        assertEquals(1, calc.modulus(7, 2));
        assertEquals(0, calc.modulus(10, 5));
        assertEquals(3, calc.modulus(15, 4));
    }

    @Test
    void testModulusByZero() {
        CalculatorAdv calc = new CalculatorAdv();
        IllegalArgumentException ex = assertThrows(
            IllegalArgumentException.class,
            () -> calc.modulus(8, 0)
        );
        assertEquals("El divisor no puede ser cero", ex.getMessage());
    }
}
