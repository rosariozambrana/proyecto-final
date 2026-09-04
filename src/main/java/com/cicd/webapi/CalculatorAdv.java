package com.cicd.webapi;

public class CalculatorAdv {
    // Elevar un número al cuadrado
    public double square(double number) {
        return number * number;
    }

    // Elevar a potencia
    public double power(double base, double exponent) {
        return Math.pow(base, exponent);
    }

    // Raíz cuadrada
    public double squareRoot(double number) {
        if (number < 0) {
            throw new IllegalArgumentException("No se puede calcular raíz de número negativo");
        }
        return Math.sqrt(number);
    }

    // Resto de una división
    public int modulus(int dividend, int divisor) {
        if (divisor == 0) {
            throw new IllegalArgumentException("El divisor no puede ser cero");
        }
        return dividend % divisor;
    }
}
