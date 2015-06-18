function corrmap = correlation_map( u1,u2,mask,W )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    gs = (1+sqrt(5))/2;
    H = fix(W/gs);
    corrmap = zeros(W,H);
    
    u1_scaled = map(u1,1,W);
    u2_scaled = map(u2,1,H);

    [sizeX,sizeY]=size(u1);
    for x=1:sizeX
        for y=1:sizeY
            if 1==mask(x,y)
                u1_coord = fix(u1_scaled(x,y));
                u2_coord = fix(u2_scaled(x,y));
                corrmap(u1_coord,u2_coord) = corrmap(u1_coord,u2_coord) + 1;
            end
        end
    end
    
    corrmap = flipud(corrmap');

end

