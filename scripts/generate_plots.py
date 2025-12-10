#!/usr/bin/env python3
"""
Generate plots from benchmark CSV data
"""

import pandas as pd
import matplotlib.pyplot as plt
import sys
import os

def create_plots():
    # Set style
    plt.style.use('seaborn-v0_8-darkgrid')
    
    # Create plots directory
    os.makedirs('results/plots', exist_ok=True)
    
    # Plot 1: Thread Scaling (k=3)
    try:
        df = pd.read_csv('results/data/thread_scaling_k3.csv')
        plt.figure(figsize=(10, 6))
        plt.plot(df['Threads'], df['Time'], marker='o', linewidth=2, markersize=8, label='Execution Time')
        plt.xlabel('Number of Threads', fontsize=12)
        plt.ylabel('Time (seconds)', fontsize=12)
        plt.title('Thread Scaling Performance (Kernel 3x3)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/plots/thread_scaling_k3.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/thread_scaling_k3.png")
    except Exception as e:
        print(f"✗ Error creating thread_scaling_k3 plot: {e}")
    
    # Plot 2: Speedup (k=3)
    try:
        df = pd.read_csv('results/data/thread_scaling_k3.csv')
        plt.figure(figsize=(10, 6))
        plt.plot(df['Threads'], df['Speedup'], marker='s', linewidth=2, markersize=8, label='Actual Speedup', color='green')
        plt.plot(df['Threads'], df['Threads'], linestyle='--', linewidth=2, label='Ideal Speedup', color='red', alpha=0.7)
        plt.xlabel('Number of Threads', fontsize=12)
        plt.ylabel('Speedup', fontsize=12)
        plt.title('Speedup vs Number of Threads (Kernel 3x3)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/plots/speedup_k3.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/speedup_k3.png")
    except Exception as e:
        print(f"✗ Error creating speedup_k3 plot: {e}")
    
    # Plot 3: Thread Scaling (k=31)
    try:
        df = pd.read_csv('results/data/thread_scaling_k31.csv')
        plt.figure(figsize=(10, 6))
        plt.plot(df['Threads'], df['Time'], marker='o', linewidth=2, markersize=8, label='Execution Time', color='purple')
        plt.xlabel('Number of Threads', fontsize=12)
        plt.ylabel('Time (seconds)', fontsize=12)
        plt.title('Thread Scaling Performance (Kernel 31x31)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/plots/thread_scaling_k31.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/thread_scaling_k31.png")
    except Exception as e:
        print(f"✗ Error creating thread_scaling_k31 plot: {e}")
    
    # Plot 4: Speedup (k=31)
    try:
        df = pd.read_csv('results/data/thread_scaling_k31.csv')
        plt.figure(figsize=(10, 6))
        plt.plot(df['Threads'], df['Speedup'], marker='s', linewidth=2, markersize=8, label='Actual Speedup', color='orange')
        plt.plot(df['Threads'], df['Threads'], linestyle='--', linewidth=2, label='Ideal Speedup', color='red', alpha=0.7)
        plt.xlabel('Number of Threads', fontsize=12)
        plt.ylabel('Speedup', fontsize=12)
        plt.title('Speedup vs Number of Threads (Kernel 31x31)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/plots/speedup_k31.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/speedup_k31.png")
    except Exception as e:
        print(f"✗ Error creating speedup_k31 plot: {e}")
    
    # Plot 5: Scheduler Comparison
    try:
        df = pd.read_csv('results/data/scheduler_comparison.csv')
        plt.figure(figsize=(10, 6))
        plt.bar(df['Scheduler'], df['Time'], color=['#3498db', '#e74c3c', '#2ecc71'], alpha=0.8)
        plt.xlabel('Scheduler Type', fontsize=12)
        plt.ylabel('Time (seconds)', fontsize=12)
        plt.title('Scheduler Comparison (4 threads, kernel 3x3)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3, axis='y')
        plt.tight_layout()
        plt.savefig('results/plots/scheduler_comparison.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/scheduler_comparison.png")
    except Exception as e:
        print(f"✗ Error creating scheduler_comparison plot: {e}")
    
    # Plot 6: Kernel Size Comparison
    try:
        df = pd.read_csv('results/data/kernel_comparison.csv')
        plt.figure(figsize=(10, 6))
        plt.plot(df['KernelSize'], df['Time'], marker='D', linewidth=2, markersize=8, color='teal')
        plt.xlabel('Kernel Size', fontsize=12)
        plt.ylabel('Time (seconds)', fontsize=12)
        plt.title('Execution Time vs Kernel Size (4 threads)', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.tight_layout()
        plt.savefig('results/plots/kernel_size_comparison.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/kernel_size_comparison.png")
    except Exception as e:
        print(f"✗ Error creating kernel_size_comparison plot: {e}")
    
    # Combined Plot: Thread Scaling Comparison
    try:
        df3 = pd.read_csv('results/data/thread_scaling_k3.csv')
        df31 = pd.read_csv('results/data/thread_scaling_k31.csv')
        
        plt.figure(figsize=(12, 6))
        plt.plot(df3['Threads'], df3['Speedup'], marker='o', linewidth=2, markersize=8, label='Kernel 3x3')
        plt.plot(df31['Threads'], df31['Speedup'], marker='s', linewidth=2, markersize=8, label='Kernel 31x31')
        plt.plot(df3['Threads'], df3['Threads'], linestyle='--', linewidth=2, label='Ideal Speedup', color='red', alpha=0.7)
        plt.xlabel('Number of Threads', fontsize=12)
        plt.ylabel('Speedup', fontsize=12)
        plt.title('Speedup Comparison: Different Kernel Sizes', fontsize=14, fontweight='bold')
        plt.grid(True, alpha=0.3)
        plt.legend()
        plt.tight_layout()
        plt.savefig('results/plots/speedup_comparison.png', dpi=300)
        plt.close()
        print("✓ Created: results/plots/speedup_comparison.png")
    except Exception as e:
        print(f"✗ Error creating speedup_comparison plot: {e}")

if __name__ == '__main__':
    print("\n" + "="*60)
    print("Generating Plots from Benchmark Data")
    print("="*60 + "\n")
    
    create_plots()
    
    print("\n" + "="*60)
    print("✅ Plot generation completed!")
    print("="*60 + "\n")
