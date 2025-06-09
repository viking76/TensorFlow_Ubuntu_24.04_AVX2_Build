

import time

def benchmark_python_operations():
    # Define a large number for operations
    size = 10000000  # Increased size for longer duration
    numbers = list(range(size))

    # Measure time for multiple iterations of list operations
    start_time = time.time()
    iterations = 125  # Adjusted number of iterations to increase duration
    for _ in range(iterations):
        result = sum(numbers)
    end_time = time.time()

    # Print the time taken
    print(f"Sum of numbers time for {iterations} iterations: {end_time - start_time:.4f} seconds")

if __name__ == "__main__":
    benchmark_python_operations()

