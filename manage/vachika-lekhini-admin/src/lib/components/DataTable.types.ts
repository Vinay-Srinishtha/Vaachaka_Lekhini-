/// Column descriptor for the shared `DataTable` component.
export interface Column {
	key: string;
	label: string;
	sortable?: boolean;
	align?: 'left' | 'right' | 'center';
	thClass?: string;
	/// Hide on viewports below the given breakpoint.
	hidden?: 'sm' | 'md' | 'lg';
}
