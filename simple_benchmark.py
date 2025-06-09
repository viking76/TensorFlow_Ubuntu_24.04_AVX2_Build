

import time

def benchmark_python_operations():
    # Define a large number for operations
    size = 1000000
    numbers = list(range(size))

    # Measure time for list operations
    start_time = time.time()
    result = sum(numbers)
    end_time = time.time()

    # Print the time taken
    print(f"Sum of numbers time: {end_time - start_time:.4f} seconds")

if __name__ == "__main__":
    benchmark_python_operations()

