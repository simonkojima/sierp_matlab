%
% siSig
% 
% Author : Simon Kojima
% Ver1.0 2021/08/26
% Ver1.1 2021/09/14
%

classdef siSig < handle
    
    properties
		data
		trig
		time
		props
		etc
    end
    
    methods

        function obj = siSig(varargin)
			if nargin > 0
				if ischar(varargin{1}) || isstring(varargin{1})
					obj.etc.filename = char(varargin{1});
					obj.data = double(bva_loadeeg(strcat(obj.etc.filename,'.vhdr')));
					trig_tmp = bva_readmarker(strcat(obj.etc.filename,'.vmrk'));
			
					obj.trig = zeros(1,size(obj.data,2));
					
					for m = 1:size(trig_tmp,2)
						obj.trig(trig_tmp(2,m)) = trig_tmp(1,m);
					end
					
					[obj.props.fs,obj.props.labels] = bva_readheader(strcat(obj.etc.filename,'.vhdr'));

					obj.etc.filter = [];

				elseif strcmpi(class(varargin{1}),'siSig')
					
					obj.data = [obj.data varargin{1}(1).data];
					obj.trig = [obj.trig varargin{1}(1).trig];
					obj.etc.filename = varargin{1}(1).etc.filename;
					obj.props = varargin{1}(1).props;
					obj.etc.filter = varargin{1}(1).etc.filter;

					for m = 1:length(varargin{1})-1
						if isequal(varargin{1}(m).props,varargin{1}(m+1).props) == 0
							error("Properties of index %d and %d are different",m,m+1);
						end	
						if isequal(varargin{1}(m).etc.filter,varargin{1}(m+1).etc.filter) == 0
							error("Filter parameters of index %d and %d are different",m,m+1)
						end
				
						obj.data = [obj.data varargin{1}(m+1).data];
						obj.trig = [obj.trig varargin{1}(m+1).trig];
						obj.etc.filename = strcat(obj.etc.filename,';',varargin{1}(m+1).etc.filename);

					end
				end	
				
				
				obj.time = (1:size(obj.data,2))/obj.props.fs;

			end
        	
        end
        
        function plot(obj,varargin)
			%winLen = varargin{1};
			%if isempty(winLen)
				winLen = 10;
			%end
        	multichanplot(obj.data,winLen,'srate',obj.props.fs,'chlabel',obj.props.labels)    
        
		end
		
		function filtfilt(obj,A,B)
			obj.etc.filter.A = A;
			obj.etc.filter.B = B;
			obj.data = filtfilt(B,A,obj.data')';
		end

		function zf = filter(obj,A,B,varargin)
			if nargin > 3
				zi = varargin{1};
			else
				zi = [];
			end
			obj.etc.filter.A = A;
			obj.etc.filter.B = B;
			[obj.data,zf] = filter(B,A,obj.data,zi,2);
		end

		function [num_trig,trig_list] = get_trig_list(obj)
			trig_list = [];
			for m = 1:length(obj.trig)
				if obj.trig(m) ~= 0
					trig_list(size(trig_list,1)+1,:) = [m obj.trig(m)];
				end
            end 
            
            trigs = trig_list(:,2);
            num_trig = unique(trigs)';
            for m = 1:length(num_trig)
                cnt(1,m) = sum(trigs == num_trig(m));
            end

            num_trig = cat(1,num_trig,cnt);

		end

    end
end

