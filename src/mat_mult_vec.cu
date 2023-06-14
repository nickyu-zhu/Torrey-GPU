#include <stdio.h>
#include "mat_mult_vec.cuh"
#include "vector.cuh"
#define TILE_WIDTH 32

// Compute C = A * B
__global__ void matrixMultiplySharedVec(Vector3f *A, Vector3f *B, float *C,
                                     int numARows, int numAColumns,
                                     int numBRows, int numBColumns,
                                     int numCRows, int numCColumns)
{
    //@@ Insert code to implement matrix multiplication here
    //@@ You have to use shared memory for this MP
    __shared__ float subTileA[TILE_WIDTH][TILE_WIDTH];
    __shared__ float subTileB[TILE_WIDTH][TILE_WIDTH];

    int bx = blockIdx.x;
    int by = blockIdx.y;
    int tx = threadIdx.x;
    int ty = threadIdx.y;
    int Row = by * TILE_WIDTH + ty;
    int Col = bx * TILE_WIDTH + tx;
    int mnum = (numAColumns - 1) / TILE_WIDTH + 1;
    float sum = 0;

    for (int m = 0; m < mnum; ++m)
    {
        if ((Row < numARows) && (m * TILE_WIDTH + tx < numAColumns))
        {
            subTileA[ty][tx] = A[Row * numAColumns + m * TILE_WIDTH + tx].x;
        }
        else
        {
            subTileA[ty][tx] = 0;
        }
        if ((Col < numBColumns) && (m * TILE_WIDTH + ty < numBRows))
        {
            subTileB[ty][tx] = B[(m * TILE_WIDTH + ty) * numBColumns + Col].x;
        }
        else
        {
            subTileB[ty][tx] = 0;
        }
        __syncthreads();
        for (int k = 0; k < TILE_WIDTH; ++k)
            sum += subTileA[ty][k] * subTileB[k][tx];
        __syncthreads();
    }

    if ((Row < numCRows) && (Col < numCColumns))
        C[Row * numCColumns + Col] = sum;
}

int mat_mult_vec(Vector3f *hostA, 
             Vector3f *hostB,
             float *hostC, 
             int numARows, 
             int numAColumns, 
             int numBRows,
             int numBColumns,
             int numCRows,   
             int numCColumns) 
{
    Vector3f *deviceA;
    Vector3f *deviceB;
    float *deviceC;

    //@@ Set numCRows and numCColumns
    numCRows = numARows;
    numCColumns = numBColumns;

    //@@ Allocate GPU memory here
    cudaMalloc((void **)&deviceA, numARows * numAColumns * sizeof(Vector3f));
    cudaMalloc((void **)&deviceB, numBRows * numBColumns * sizeof(Vector3f));
    cudaMalloc((void **)&deviceC, numCRows * numCColumns * sizeof(float));

    //@@ Copy memory to the GPU here
    cudaMemcpy(deviceA, hostA, numARows * numAColumns * sizeof(Vector3f), cudaMemcpyHostToDevice);
    cudaMemcpy(deviceB, hostB, numBRows * numBColumns * sizeof(Vector3f), cudaMemcpyHostToDevice);

    //@@ Initialize the grid and block dimensions here
    dim3 DimGrid(ceil(((float)numCColumns) / TILE_WIDTH), ceil(((float)numCRows) / TILE_WIDTH), 1);
    dim3 DimBlock(TILE_WIDTH, TILE_WIDTH, 1);

    //@@ Launch the GPU Kernel here
    matrixMultiplySharedVec<<<DimGrid, DimBlock>>>(deviceA, deviceB, deviceC,
                                                   numARows, numAColumns,
                                                   numBRows, numBColumns,
                                                   numCRows, numCColumns);

    cudaDeviceSynchronize();

    //@@ Copy the GPU memory back to the CPU here
    cudaMemcpy(hostC, deviceC, numCRows * numCColumns * sizeof(float), cudaMemcpyDeviceToHost);

    //@@ Free the GPU memory here
    cudaFree(deviceA);
    cudaFree(deviceB);
    cudaFree(deviceC);

    return 0;
}