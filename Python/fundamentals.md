# Python Fundamentals


**Q1. What is the difference between a list, tuple, and set?**  
✅ **List:** Ordered, mutable, allows duplicates (`[1,2,3]`)  
✅ **Tuple:** Ordered, immutable, allows duplicates (`(1,2,3)`)  
✅ **Set:** Unordered, mutable, **no duplicates** (`{1,2,3}`)

---

**Q2. What are Python decorators?**  
Decorators are functions that **modify the behavior** of another function — often used for **logging, authentication, or timing**.

```
def decorator(func):
    def wrapper():
        print("Before function")
        func()
        print("After function")
    return wrapper

@decorator
def say_hello():
    print("Hello")

say_hello()

```

---

**Q3. What’s the difference between shallow and deep copy?**

- **Shallow copy** creates a new object but references the same nested objects.
    
- **Deep copy** creates new independent copies of nested objects.
    

```
import copy
a = [[1, 2], [3, 4]]
b = copy.deepcopy(a)

```

---

**Q4. What is the difference between `is` and `==`?**

- `is` → compares **memory location (identity)**
    
- `==` → compares **values (content)**
    

---

**Q5. What are Python generators?**  
Generators are **functions that yield values one at a time**, saving memory — often used in **data streaming**.

```
def generate_numbers():
    for i in range(5):
        yield i

```

---

## 🧮 **2. Data Handling and Pandas**

**Q6. How do you handle missing values in Pandas?**

```
df.dropna()        # remove missing rows
df.fillna(0)       # replace missing values
df.isnull().sum()  # check missing count

```

---

**Q7. How do you merge or join two DataFrames in Pandas?**

`pd.merge(df1, df2, on='id', how='inner')   # inner, left, right, outer`

---

**Q8. How do you read and write CSV or Parquet files?**

```
df = pd.read_csv("data.csv") 
df.to_parquet("data.parquet")
```

---

**Q9. How do you apply a function to each row or column?**

```
df["col2"] = df["col1"].apply(lambda x: x * 2)
```

---

**Q10. How do you remove duplicate rows?**

```
df.drop_duplicates(inplace=True)
```

---

## ⚙️ **3. File and Data Processing**

**Q11. How can you process large files efficiently in Python?**  
Use **generators**, **chunks**, or **iterators** instead of loading the entire file:

```
for chunk in pd.read_csv("data.csv", chunksize=10000):
    process(chunk)

```

---

**Q12. How do you connect Python to a database?**  
Using `psycopg2`, `pyodbc`, or `SQLAlchemy`:

```
import psycopg2 conn = psycopg2.connect(database="testdb", user="user", password="pwd")
```

---

**Q13. How do you read data from an API in Python?**

```
import requests 
response = requests.get("https://api.example.com/data") 
data = response.json()
```

---

## 🔥 **4. PySpark and Big Data Focus**

**Q14. What is the difference between Pandas and PySpark DataFrame?**

- **Pandas** → works in memory (single machine)
    
- **PySpark** → distributed processing (cluster)
    

---

**Q15. How do you read data in PySpark?**

```
df = spark.read.csv("data.csv", header=True, inferSchema=True)
```

---

**Q16. How to perform group by and aggregation in PySpark?**

```
df.groupBy("category").agg({"sales": "sum"}).show()
```

---

## 🧠 **5. Coding/Logic-Based Questions**

**Q17. Reverse a string without using built-in functions.**

```
s = "data" 
rev = "" 
for i in s:     
	rev = i + rev 
print(rev)
```

---

**Q18. Find duplicates in a list.**

```
nums = [1,2,3,2,4,1] 
duplicates = set([x for x in nums if nums.count(x) > 1])
```

---

**Q19. Count word frequency in a string.**

```
from collections
import Counter text = "data engineer data" 
Counter(text.split())
```

---

**Q20. How do you handle exceptions in Python?**

```
try:     
	result = 10 / 0 
except ZeroDivisionError:     
	print("Cannot divide by zero") 
finally:     
	print("Done")
```

---

## 💡 **6. Bonus: Data Engineering Focused Python Topics**

|Topic|Why it matters|
|---|---|
|**Logging**|For tracking ETL pipeline issues|
|**Argparse**|For handling command-line arguments in scripts|
|**Datetime**|For working with timestamps in ETL|
|**OS & Pathlib**|For managing file systems dynamically|
|**Multiprocessing / Threading**|For parallel data processing|
|**Airflow Operators (PythonOperator, BashOperator)**|For orchestrating Python ETL workflows|

## 🧠 **What are Data Types in Python?**

In Python, **data types** define the **kind of value** a variable can hold —  
like numbers, text, lists, or True/False values.

Python automatically detects the type when you assign a value.  
Example:

`x = 10          # int y = 3.14        # float name = "Afsal"  # str`

---

## 🧩 **1. Basic (Primitive) Data Types**

|Type|Example|Description|
|---|---|---|
|**int**|`x = 10`|Integer numbers (no decimals)|
|**float**|`y = 3.14`|Decimal numbers|
|**complex**|`z = 2 + 3j`|Complex numbers (used in math)|
|**str**|`name = "Afsal"`|Text (string of characters)|
|**bool**|`is_valid = True`|Boolean values (`True` or `False`)|
|**NoneType**|`data = None`|Represents no value or empty state|

---

## 🧺 **2. Collection (Data Structure) Types**

These hold **multiple values**.

| Type      | Example                        | Description                            |
| --------- | ------------------------------ | -------------------------------------- |
| **list**  | `[1, 2, 3, 4]`                 | Ordered, changeable, allows duplicates |
| **tuple** | `(1, 2, 3, 4)`                 | Ordered, **unchangeable (immutable)**  |
| **set**   | `{1, 2, 3}`                    | Unordered, **no duplicates**           |
| **dict**  | `{"name": "Afsal", "age": 25}` | Key–value pairs (like a mini database) |

## 🧠 **Difference between `*args` and `**kwargs` in Python**

They are **special parameters** used in function definitions  
to pass a **variable number of arguments**.

---

### 🔹 **1. `*args` → Non-keyword (positional) arguments**

✅ Used when you **don’t know how many positional arguments** will be passed to a function.

It collects all **extra arguments** into a **tuple**.

**Example:**

```
def add_numbers(*args):
    print(args)

add_numbers(1, 2, 3)

```

### 🔹 **2. `**kwargs` → Keyword (named) arguments**

✅ Used when you **don’t know how many keyword arguments** (key–value pairs) will be passed.

It collects all **extra keyword arguments** into a **dictionary**.

**Example:**

```
def show_details(**kwargs):
    print(kwargs)

show_details(name="Afsal", age=25, role="Data Engineer")

```


### 🔹 **3. You can use both together**

Just remember the **order matters** → `*args` comes before `**kwargs`.

```
def example_func(*args, **kwargs):
    print("Args:", args)
    print("Kwargs:", kwargs)

example_func(10, 20, name="Afsal", job="Engineer")

```


## 🧠 **What is GIL?**

- **GIL** stands for **Global Interpreter Lock**.
    
- It is a **mutex (lock)** that allows **only one thread to execute Python bytecode at a time**, even if you have multiple CPU cores.
    
- This is specific to **CPython**, the standard Python implementation.
    

---

## 🔹 **Why GIL Exists**

Python’s memory management is **not thread-safe by default**.  
GIL ensures that only **one thread executes Python code at a time**, which prevents **race conditions** in memory operations.

---

## 🔹 **How GIL Affects Threading**

- **I/O-bound tasks (networking, file reading/writing)** → Threading is still **useful**, because while one thread is waiting for I/O, another thread can run. ✅
    
- **CPU-bound tasks (heavy computation)** → Threading **does NOT speed up** execution due to GIL. ❌ For CPU-heavy tasks, use **multiprocessing** instead.


# **1️⃣ List Functions & Methods**

A **list** is an **ordered, mutable collection**.

### **Common Methods**

|Method|Description|Example|
|---|---|---|
|`append(x)`|Add element `x` at the end|`lst.append(5)`|
|`extend(iterable)`|Add multiple elements|`lst.extend([6,7])`|
|`insert(i, x)`|Insert `x` at index `i`|`lst.insert(1, 100)`|
|`remove(x)`|Remove first occurrence of `x`|`lst.remove(5)`|
|`pop([i])`|Remove & return element at index `i` (default last)|`lst.pop()`|
|`clear()`|Remove all elements|`lst.clear()`|
|`index(x)`|Return index of first occurrence|`lst.index(7)`|
|`count(x)`|Count occurrences of `x`|`lst.count(7)`|
|`sort()`|Sort list ascending (use `reverse=True` for descending)|`lst.sort()`|
|`reverse()`|Reverse the list|`lst.reverse()`|
|`copy()`|Return a shallow copy of the list|`lst2 = lst.copy()`|

---

# **2️⃣ Set Functions & Methods**

A **set** is an **unordered collection of unique elements**.

### **Common Methods**

|Method|Description|Example|
|---|---|---|
|`add(x)`|Add element `x`|`s.add(5)`|
|`remove(x)`|Remove `x` (error if not present)|`s.remove(5)`|
|`discard(x)`|Remove `x` (no error if not present)|`s.discard(6)`|
|`pop()`|Remove & return arbitrary element|`s.pop()`|
|`clear()`|Remove all elements|`s.clear()`|
|`union(s2)`|Return union with another set|`s.union(s2)`|
|`update(s2)`|Add elements from another set|`s.update(s2)`|
|`intersection(s2)`|Return common elements|`s.intersection(s2)`|
|`intersection_update(s2)`|Keep only common elements|`s.intersection_update(s2)`|
|`difference(s2)`|Elements in `s` not in `s2`|`s.difference(s2)`|
|`difference_update(s2)`|Remove elements in `s2` from `s`|`s.difference_update(s2)`|
|`symmetric_difference(s2)`|Elements in either `s` or `s2` but not both|`s.symmetric_difference(s2)`|
|`isdisjoint(s2)`|True if sets have no elements in common|`s.isdisjoint(s2)`|
|`issubset(s2)`|True if `s` is subset of `s2`|`s.issubset(s2)`|
|`issuperset(s2)`|True if `s` is superset of `s2`|`s.issuperset(s2)`|
|`copy()`|Return a shallow copy|`s2 = s.copy()`|

---

# **3️⃣ Dictionary Functions & Methods**

A **dictionary (dict)** is an **unordered collection of key–value pairs**.

### **Common Methods**

|Method|Description|Example|
|---|---|---|
|`dict.get(key)`|Return value for key (None if not found)|`d.get('name')`|
|`dict.keys()`|Return all keys|`d.keys()`|
|`dict.values()`|Return all values|`d.values()`|
|`dict.items()`|Return key-value pairs|`d.items()`|
|`dict.update(d2)`|Update dict with another dict|`d.update({'age':26})`|
|`dict.pop(key)`|Remove key & return value|`d.pop('name')`|
|`dict.popitem()`|Remove & return last inserted item|`d.popitem()`|
|`dict.clear()`|Remove all items|`d.clear()`|
|`dict.copy()`|Return a shallow copy|`d2 = d.copy()`|
|`dict.setdefault(key, value)`|Insert key with value if not exists|`d.setdefault('role','Engineer')`|
|`dict.fromkeys(seq, value)`|Create dict from keys with same value|`dict.fromkeys(['a','b'],0)`|
