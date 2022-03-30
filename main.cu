#include <fstream>
#include <iostream>
#include <string>
#include <cstdio>
#include <bits/stdc++.h>
#include <vector>
#include <stdlib.h>
#include <utility>

using namespace std;

__global__ void AverageFinder(int* dM, int* dA, int d_rows, int d_cols, int q_rows, int q_cols){
	int avg = 100;
	printf("Thread: %d%d\n", threadIdx.x, threadIdx.y);
	for(int i=threadIdx.x; i<threadIdx.x + q_rows; i++){
		for(int j=threadIdx.y; i<threadIdx.y + q_cols; j++){
			avg += (dM[i*q_cols*3 + j*3] + dM[i*q_cols*3 + j*3 + 1] + dM[i*q_cols*3 + j*3 + 2]);
		}
	}
	printf("sum = %d\n", avg);
	// avg /= q_rows * q_cols;
	printf("avg = %d\n", avg);
	dA[threadIdx.x * (d_rows - q_rows + 1) + threadIdx.y] = avg;
}

int main(int argc, char* argv[]){

	if(argc < 5){
		cout<<"insufficient args provided\n";
		return -1;
	}

	ifstream image_file(argv[1], ios::in);
	ifstream query_file(argv[2], ios::in);
	int threshold = atoi(argv[3]);
	int topn = atoi(argv[4]);

	int d_rows,d_cols;
	image_file>>d_rows;
	image_file>>d_cols;

	int *input_img = new int[d_rows * d_cols * 3];

	for(int idx=0; idx<d_rows; idx++){
		for(int jdx=0; jdx<d_cols; jdx++){
			for(int kdx=0; kdx<3; kdx++){
				image_file>>input_img[idx*d_cols*3 + jdx*3 + kdx];
			}
		}
	}
	image_file.close();

	int q_rows,q_cols;
	query_file>>q_rows;
	query_file>>q_cols;

	int *query_img = new int[q_rows * q_cols * 3];
	
	for(int idx=0;idx<q_rows;idx++){
		for(int jdx=0;jdx<q_cols;jdx++){
			for(int kdx=0;kdx<3;kdx++){
				query_file>>query_img[idx*q_cols*3 + jdx*3 + kdx];
			}
		}
	}

	query_file.close();

	//memory allocation for gpu
	int *dM, *dQ;
	cudaMalloc(&dM, d_rows*d_cols * 3 * sizeof(int));
	cudaMalloc(&dQ, q_rows*q_cols * 3 * sizeof(int));
	cudaMemcpy(dM, input_img, d_rows * d_cols * 3 * sizeof(int), cudaMemcpyDefault);
	cudaMemcpy(dQ, query_img, q_rows * q_cols * 3 * sizeof(int), cudaMemcpyDefault);

	//storing average distances
	int *dA;				
	cudaMalloc(&dA, (d_rows - q_rows + 1) * (d_cols - q_cols + 1) * sizeof(int));

	//kernel invocation
	dim3 dimBlock((d_rows - q_rows + 1) , (d_cols - q_cols + 1));
	AverageFinder<<<1, dimBlock>>>(dM, dA, d_rows, d_cols, q_rows, q_cols);


	cudaDeviceSynchronize();
	//getback from the kernel
	int *A = new int[(d_rows - q_rows + 1) * (d_cols - q_cols + 1)];
	int *Topn = new int[topn * 3];
	cudaMemcpy(A, dA, (d_rows - q_rows + 1) * (d_cols - q_cols + 1) * sizeof(int), cudaMemcpyDefault);
	cudaFree(dM);
	cudaFree(dQ);
	cudaFree(dA);

	//debug
	for(int i=0;i< (d_rows - q_rows + 1) * (d_cols - q_cols + 1); i++){
		cout<<A[i]<<" ";
	}
	cout<<"\nDone printing A\n";
	
	//calculate topntriplets

	ofstream output_file("output.txt", ios::out);
	for(int i=0;i<topn * 3;i+=3){
		output_file<<Topn[i]<<" "<<Topn[i+1]<<" "<<Topn[i+2]<<"\n";
	}
	output_file.close();
	return 0;
}
