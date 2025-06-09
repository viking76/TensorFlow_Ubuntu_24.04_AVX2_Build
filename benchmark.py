
import tensorflow as tf
import time

def benchmark_matrix_multiplication():
    # Define matrix dimensions
    size = 1000
    a = tf.random.normal([size, size])
    b = tf.random.normal([size, size])

    # Warm-up run
    _ = tf.matmul(a, b)

    # Measure time for matrix multiplication
    start_time = time.time()
    result = tf.matmul(a, b)
    end_time = time.time()

    # Print the time taken
    print(f"Matrix multiplication time: {end_time - start_time:.4f} seconds")

if __name__ == "__main__":
    benchmark_matrix_multiplication()
