#!/usr/bin/env sage
import sys
import os

# Converts value to 16-character hexadecimal chunks.
def hexify_to_chunks(value, num_chunks=4):
    correct_length = (num_chunks == 4 or num_chunks == 5)
    assert(correct_length)

    hex_representation = str(hex(value)).split('x')[-1]
    hex_length = 64
    if num_chunks == 5:
        hex_length = 80

    padded = hex_representation.rjust(hex_length, '0')

    chunk_length = 16
    assert(num_chunks * chunk_length >= len(padded))

    output = ""
    for i in range(0, num_chunks):
        start = (num_chunks - i - 1) * chunk_length
        end = start + chunk_length
        output += "0x"
        output += padded[start:end]
        output += ","

        if i < num_chunks - 1:
            output += " "

    return output

def compute_t_s(modulus):
    T = modulus - 1
    S = 0
    while T%2==0:
        S = S+1
        T = T/2 
    return int(T), int(S)

def square_mult_reduce(base, power, modulo):
    power_string = str(bin(power)).split('b')[-1]
    number_of_rounds = len(power_string)
    result = base
    for i in range(1, number_of_rounds):
        result = result ** 2 % modulo
        if power_string[i] == '1':
            result = result * base % modulo
            
    return result

def compute_mod_bits(modulus):
    return len(str(bin(modulus)).split('b')[-1])

def compute_params(modulus, generator=None):
    mod_bits = compute_mod_bits(modulus)

    capacity = mod_bits - 1
    repr_shave_bits = 256 - mod_bits
    if repr_shave_bits <= 0:
        repr_shave_bits = 64

    r_exp = int()
    if mod_bits % 64 == 0:
        r_exp = mod_bits + 64
    if mod_bits < 256:
        r_exp = 256

    r = (2 ** r_exp) % modulus

    r2 = (r ** 2) % modulus
    inv = -(1 / modulus) % (2 ** 64)

    # Note that his takes a few seconds to compute
    if generator is None:
        field = GF(modulus)
        generator = field.multiplicative_generator()
    else:
        generator = int(generator)

    generator = generator * r % modulus

    modulus_minus_one_div_two = (modulus - 1) / 2
    t, s = compute_t_s(modulus)
    t_minus_one_div_two = int((t - 1)/2)
    two_acidity = s
    two_adic_root_of_unity = int(square_mult_reduce(generator, t, modulus) * r % modulus)

    return {
        'MODULUS': modulus,
        'MODULUS_BITS': mod_bits,
        'CAPACITY': capacity,
        'REPR_SHAVE_BITS': repr_shave_bits,
        'R': r,
        'R2': r2,
        'MODULUS_MINUS_ONE_DIV_TWO': modulus_minus_one_div_two,
        'GENERATOR': generator,
        'INV': inv,
        'T': t,
        'T_MINUS_ONE_DIV_TWO': t_minus_one_div_two,
        'TWO_ADICITY': two_acidity,
        'TWO_ADIC_ROOT_OF_UNITY': two_adic_root_of_unity
    }

def main(modulus, generator=None):
    mod_bits = compute_mod_bits(modulus)
    to_hex = hexify_to_chunks
    if mod_bits == 256:
        to_hex = lambda value: hexify_to_chunks(value, 5)

    params = compute_params(modulus, generator)
    for key, val in params.items():
        print("{}: {}\n{}\n".format(key, val, to_hex(val)))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Please specify the field modulus (and optionally, the generator) as such:")
        print("sage", __file__, "<FIELD MODULUS> <GENERATOR (optional)>")
    else:
        modulus_str = sys.argv[1]
        if modulus_str.startswith('0x'):
            modulus_str = int(sys.argv[1], 16)
        else:
            modulus_str = int(sys.argv[1], 10)

        if len(sys.argv) > 2:
            generator = sys.argv[2]
            main(modulus_str, generator)
        else:
            main(modulus_str)
