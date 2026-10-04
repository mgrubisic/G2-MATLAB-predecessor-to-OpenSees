function order=rcm(adjacency)
% RCM Reverse Cuthill-McKee, degree-ordered BFS over all connected components.
% Returns old equation indices in new order. No toolbox dependency.
if size(adjacency,1)~=size(adjacency,2), error('G2Dyn:Graph','Adjacency must be square.'); end
n=size(adjacency,1); A=spones(sparse(adjacency)+sparse(adjacency)');
A=A-spdiags(diag(A),0,n,n); degree=full(sum(A~=0,2));
seen=false(n,1); order=zeros(1,n); cursor=0;
while any(~seen)
    remaining=find(~seen); [~,j]=min(degree(remaining)); root=remaining(j);
    % Pseudo-peripheral root improves numbering of irregular meshes.
    [~,depth]=levels(root,A,seen); previous=-1;
    while depth>previous
        previous=depth; [last,~]=levels(root,A,seen);
        [~,j]=min(degree(last)); candidate=last(j);
        [~,depth]=levels(candidate,A,seen);
        if depth>previous, root=candidate; end
    end
    queue=zeros(1,n); queue(1)=root; seen(root)=true; head=1; tail=1;
    while head<=tail
        v=queue(head); head=head+1;
        next=find(A(v,:)&~seen');
        if ~isempty(next)
            sorted=sortrows([degree(next) next(:)],[1 2]); next=sorted(:,2)';
            queue(tail+(1:numel(next)))=next; tail=tail+numel(next); seen(next)=true;
        end
    end
    order(cursor+(1:tail))=queue(tail:-1:1); cursor=cursor+tail;
end
end
function [last,depth]=levels(root,A,excluded)
visited=excluded; visited(root)=true; last=root; depth=0;
while true
    next=find(any(A(last,:),1)&~visited');
    if isempty(next), return; end
    visited(next)=true; last=next; depth=depth+1;
end
end
