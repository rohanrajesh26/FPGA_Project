# Problems faced
## a) Probing array elements in ILA:
The ILA buffer captures the array in a circular fashion. Say the window size is 4096 and array size is 1024, then we got the array to repeat 4 times, but the start index at the first window sample was random every time we ran the ILA. To solve this issue, we used a capture_active signal as a trigger. What this signal does is that it is high when the array elements are valid, and low when they’re not. 

So we can use the rising edge of this signal as a trigger to indicate which is the first element of the output array. We also used the following command in Tcl to shift the trigger from the middle window sample to the 0th window sample:

```
set_property CONTROL.TRIGGER_POSITION 0 [get_hw_ilas hw_ila_1]
```
![97332443-a623-42e3-b729-51ba0a7ae870-1](https://github.com/user-attachments/assets/63312353-6f26-4a05-8cf8-5e0ac0bd4617)


## b) BRAM Usage
We have 3 parameters in our CPP code which determine the usage of BRAMs:
1. MAX_DICT_SIZE 
- Size of the dictionary to store unique patterns.  
2. MAX_SEQ_LEN
- Size of each pattern/sequence.
3. MAX_INPUT_SIZE
- Size of the input array.
After experimenting with these values, we found out that all three parameters affect the BRAM usage linearly. 
We decided that 16x16 would be the best size we can work with because of the following reasons:
16x16 input means that MAX_INPUT_SIZE needs to be 256.
MAX_DICT_SIZE used as 2048 to capture as many unique patterns as possible.
MAX_SEQ_LEN used as 32. This can be increased more for capturing complex and lengthy patterns, but due to BRAMs exceeding max capacity we had to use this.

To solve this, we used ZedBoard which has much more BRAMs than Basys3.
![384488122-6f3431fd-1ab3-4475-b9f2-3631008914e7](https://github.com/user-attachments/assets/0eb99eed-34cd-4609-9ce3-817c7d7c6f16)

