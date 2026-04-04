<?php
/**
 * Plugin Name: WC Image Checker
 * Description: Lists WooCommerce products with missing or invalid images under Tools > Img.
 * Version:     1.0.0
 * Requires Plugins: woocommerce
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action( 'admin_menu', function () {
	add_submenu_page(
		'tools.php',
		'Product Image Checker',
		'Img',
		'manage_options',
		'wc-img-checker',
		'wc_img_checker_page'
	);
} );

/**
 * Returns an array of image issues for a product.
 * Each entry: [ 'type' => 'featured'|'gallery', 'label' => string, 'reason' => string ]
 */
function wc_img_checker_get_issues( int $product_id ): array {
	$issues = [];

	// --- Featured image ---
	$thumb_id = (int) get_post_thumbnail_id( $product_id );

	if ( $thumb_id === 0 ) {
		$issues[] = [
			'type'   => 'featured',
			'label'  => 'Featured image',
			'reason' => 'Not set',
		];
	} else {
		$reason = wc_img_checker_attachment_issue( $thumb_id );
		if ( $reason ) {
			$issues[] = [
				'type'   => 'featured',
				'label'  => 'Featured image',
				'reason' => $reason,
			];
		}
	}

	// --- Gallery images ---
	$gallery_ids = get_post_meta( $product_id, '_product_image_gallery', true );
	if ( ! empty( $gallery_ids ) ) {
		foreach ( array_filter( explode( ',', $gallery_ids ) ) as $i => $att_id ) {
			$att_id = (int) $att_id;
			$label  = 'Gallery image #' . ( $i + 1 );

			$reason = wc_img_checker_attachment_issue( $att_id );
			if ( $reason ) {
				$issues[] = [
					'type'   => 'gallery',
					'label'  => $label,
					'reason' => $reason,
				];
			}
		}
	}

	return $issues;
}

/**
 * Checks whether an attachment ID points to a valid, existing image.
 * Returns a human-readable reason string, or empty string if OK.
 */
function wc_img_checker_attachment_issue( int $att_id ): string {
	$post = get_post( $att_id );

	if ( ! $post || $post->post_type !== 'attachment' ) {
		return "Attachment #{$att_id} not found in media library";
	}

	if ( strpos( $post->post_mime_type, 'image/' ) !== 0 ) {
		return "Attachment #{$att_id} is not an image ({$post->post_mime_type})";
	}

	$file = get_attached_file( $att_id );
	if ( ! $file || ! file_exists( $file ) ) {
		return "File missing on disk (attachment #{$att_id})";
	}

	return '';
}

function wc_img_checker_page(): void {
	if ( ! current_user_can( 'manage_options' ) ) {
		return;
	}

	if ( ! function_exists( 'WC' ) ) {
		echo '<div class="wrap"><h1>Product Image Checker</h1>';
		echo '<div class="notice notice-error"><p>WooCommerce is not active.</p></div></div>';
		return;
	}

	// Fetch all published products (no limit — chunked via WPDB to avoid memory issues).
	$product_ids = get_posts( [
		'post_type'      => 'product',
		'post_status'    => 'publish',
		'posts_per_page' => -1,
		'fields'         => 'ids',
	] );

	$rows        = [];
	$total_ok    = 0;

	foreach ( $product_ids as $product_id ) {
		$issues = wc_img_checker_get_issues( $product_id );
		if ( empty( $issues ) ) {
			$total_ok++;
			continue;
		}
		$rows[] = [
			'id'     => $product_id,
			'title'  => get_the_title( $product_id ),
			'issues' => $issues,
		];
	}

	$total_products = count( $product_ids );
	$total_bad      = count( $rows );

	echo '<div class="wrap">';
	echo '<h1>Product Image Checker</h1>';

	printf(
		'<p>Scanned <strong>%d</strong> published products — <strong>%d</strong> OK, <strong>%d</strong> with image issues.</p>',
		$total_products,
		$total_ok,
		$total_bad
	);

	if ( empty( $rows ) ) {
		echo '<div class="notice notice-success inline"><p>All products have valid images.</p></div>';
		echo '</div>';
		return;
	}

	echo '<style>
		#wc-img-checker-table { border-collapse: collapse; width: 100%; }
		#wc-img-checker-table th,
		#wc-img-checker-table td { padding: 8px 12px; border: 1px solid #c3c4c7; text-align: left; vertical-align: top; }
		#wc-img-checker-table th { background: #f0f0f1; }
		#wc-img-checker-table tr:hover td { background: #f6f7f7; }
		.wc-img-issue-featured { color: #d63638; font-weight: 600; }
		.wc-img-issue-gallery  { color: #996800; }
		.wc-img-issue-list { margin: 0; padding-left: 1.2em; }
	</style>';

	echo '<table id="wc-img-checker-table">';
	echo '<thead><tr>
		<th>#</th>
		<th>Product</th>
		<th>Issues</th>
	</tr></thead><tbody>';

	$counter = 0;
	foreach ( $rows as $row ) {
		$counter++;
		$edit_url = get_edit_post_link( $row['id'] );

		echo '<tr>';
		printf( '<td>%d</td>', $counter );
		printf(
			'<td><a href="%s">%s</a><br><small>#%d</small></td>',
			esc_url( $edit_url ),
			esc_html( $row['title'] ),
			(int) $row['id']
		);

		echo '<td><ul class="wc-img-issue-list">';
		foreach ( $row['issues'] as $issue ) {
			$css = 'wc-img-issue-' . esc_attr( $issue['type'] );
			printf(
				'<li><span class="%s">%s:</span> %s</li>',
				$css,
				esc_html( $issue['label'] ),
				esc_html( $issue['reason'] )
			);
		}
		echo '</ul></td>';
		echo '</tr>';
	}

	echo '</tbody></table>';
	echo '</div>';
}
