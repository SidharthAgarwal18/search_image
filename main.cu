#include <stdio.h>
#include <iostream>
#include <fstream>

using namespace std;
__global__ 
void AverageFinder(int* dM, int *dQ, int d_rows, int d_cols, int q_rows, int q_cols, int qavg, int th1)
{
	int avg = 0;
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	// printf("threadidx:%d\n",i);
	for(int r = 0; r<q_rows; r++){
		for(int c = 0; c<q_cols; c++){
			avg += (dM[i*3 + r*d_cols*3 + c*3] + dM[i*3 + r*d_cols*3 + c*3 + 1] + dM[i*3 + r*d_cols*3 + c*3 + 2])/3;
		}
	}

	avg /= (q_rows * q_cols);
	//printf("avg : %d\n",avg);
	if(abs(qavg - avg) <= th1){
		double total = 0;
		for(int r = 0; r<q_rows; r++){
			for(int c = 0; c<q_cols; c++){
				for(int k = 0; k<3; k++){
					long v = dM[i*3 + r*d_cols*3 + c*3 + k] - dQ[r*q_cols*3 + c*3 + k];
					total += v * v;
				}
			}
		}
		total /= (q_cols*q_rows*3);
		total = sqrt(total);
		printf("%d is close, RMSD : %f\n",i,total);
	}

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
	cudaMemcpy(dM, input_img, d_rows * d_cols * 3 * sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(dQ, query_img, q_rows * q_cols * 3 * sizeof(int), cudaMemcpyHostToDevice);

	//get query imae avg
	int qavg = 0;
	for(int i=0; i<q_rows * q_cols * 3; i+=3){
		qavg += (query_img[i] + query_img[i+1] + query_img[i+2])/3;
	}
	qavg /= (q_cols * q_rows);
	// cout<<"qavg :"<<qavg<<'\n';

	int th1 = 1;

	//kernel invocation
	int N = (d_rows - q_rows + 1) * (d_cols - q_cols + 1);
	AverageFinder<<<(N + 255)/256,256>>>(dM, dQ, d_rows, d_cols, q_rows, q_cols, qavg, th1);


	cudaDeviceSynchronize();
	//getback from the kernel
	int *Topn = new int[topn * 3];

	cudaFree(dM);
	cudaFree(dQ);
	//calculate topntriplets

	ofstream output_file("output.txt", ios::out);
	for(int i=0;i<topn * 3;i+=3){
		output_file<<Topn[i]<<" "<<Topn[i+1]<<" "<<Topn[i+2]<<"\n";
	}
	output_file.close();
	return 0;
}
