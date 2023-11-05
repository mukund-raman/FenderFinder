import tensorflow as tf

# Load the TFLite model and allocate tensors.
interpreter = tf.lite.Interpreter(model_path="../FenderFinderApp/default.tflite")
interpreter.allocate_tensors()

# Get input and output tensors.
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

# Print input and output details to console.
print(input_details)
print(output_details)

# Retrieve the input tensor shape.
input_shape = input_details[0]['shape']
print('Input shape:', input_shape)