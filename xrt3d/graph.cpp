extern "C" {
#include "xrt3d.h"
}
#include <iostream.h>
#include <String.h>
#include <string.h>
#include <stdlib.h>

int main(int argc, char ** argv)
{
    struct xrt3d_info graph_cfg;
    const int line_size = 1000;
    char text_line[line_size+1];

    graph_cfg.argc = argc;
    graph_cfg.argv = argv;
    cin.getline(text_line, line_size);
    graph_cfg.filename = strdup(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.x_min = atoi(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.y_min = atoi(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.x_step = atoi(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.y_step = atoi(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.x_cnt = atoi(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.y_cnt = atoi(text_line);

    int i,j;
    String data_row;
    String row_chunks[graph_cfg.y_cnt];
    graph_cfg.data = new double*[graph_cfg.x_cnt];
    for (i = 0; i < graph_cfg.x_cnt; i++) {
        cin.getline(text_line, line_size);
	data_row = text_line;
	split(data_row, row_chunks, graph_cfg.y_cnt, (String)" ");
        graph_cfg.data[i] = new double[graph_cfg.y_cnt];
	for (j = 0; j < graph_cfg.y_cnt; j++) {
	    graph_cfg.data[i][j] = atof(row_chunks[j]);
	}
    }
    int num_headers, num_footers;
    cin.getline(text_line, line_size);
    num_headers = atoi(text_line);
    graph_cfg.header = new char*[num_headers+1];
    for (i = 0; i < num_headers; i++) {
        cin.getline(text_line, line_size);
        graph_cfg.header[i] = strdup(text_line);
    }
    graph_cfg.header[i] = NULL;

    cin.getline(text_line, line_size);
    num_footers = atoi(text_line);
    graph_cfg.footer = new char*[num_footers+1];
    for (i = 0; i < num_footers; i++) {
        cin.getline(text_line, line_size);
        graph_cfg.footer[i] = strdup(text_line);
    }
    graph_cfg.footer[i] = NULL;

    cin.getline(text_line, line_size);
    graph_cfg.x_title = strdup(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.y_title = strdup(text_line);
    cin.getline(text_line, line_size);
    graph_cfg.z_title = strdup(text_line);

    graph_cfg.x_labels = new char*[graph_cfg.x_cnt+1];
    for (i = 0; i < graph_cfg.x_cnt; i++) {
        cin.getline(text_line, line_size);
        graph_cfg.x_labels[i] = strdup(text_line);
    }
    graph_cfg.x_labels[i] = NULL;

    graph_cfg.y_labels = new char*[graph_cfg.y_cnt+1];
    for (i = 0; i < graph_cfg.y_cnt; i++) {
        cin.getline(text_line, line_size);
        graph_cfg.y_labels[i] = strdup(text_line);
    }
    graph_cfg.y_labels[i] = NULL;

    graph_xrt3d(&graph_cfg);
}
