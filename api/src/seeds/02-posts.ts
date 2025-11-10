/**
 * Seed Posts
 * Creates sample blog posts/content for development
 */

import { Pool } from 'pg';

export async function seedPosts(pool: Pool): Promise<void> {
  console.log('  → Seeding posts...');

  // Get user IDs to assign posts
  const usersResult = await pool.query('SELECT id, username FROM users ORDER BY id LIMIT 5');
  const users = usersResult.rows;

  if (users.length === 0) {
    console.log('    ! No users found, skipping posts seeding');
    return;
  }

  const posts = [
    {
      user_id: users[0]?.id,
      title: 'Welcome to Wander',
      content: 'This is the first post on Wander. Welcome to our platform!',
      status: 'published',
    },
    {
      user_id: users[1]?.id,
      title: 'Getting Started with Node.js',
      content: 'Node.js is a powerful platform for building scalable applications. Here are some tips to get started...',
      status: 'published',
    },
    {
      user_id: users[1]?.id,
      title: 'Understanding TypeScript',
      content: 'TypeScript adds static typing to JavaScript, making your code more robust and maintainable.',
      status: 'published',
    },
    {
      user_id: users[2]?.id,
      title: 'Docker for Developers',
      content: 'Docker containers make it easy to package and deploy applications consistently across environments.',
      status: 'published',
    },
    {
      user_id: users[2]?.id,
      title: 'Draft: Database Design Patterns',
      content: 'This post is still being written. Coming soon!',
      status: 'draft',
    },
    {
      user_id: users[3]?.id,
      title: 'Building RESTful APIs',
      content: 'RESTful APIs follow a set of architectural principles that make them scalable and maintainable.',
      status: 'published',
    },
    {
      user_id: users[4]?.id,
      title: 'React Best Practices',
      content: 'Learn the best practices for building React applications that scale.',
      status: 'published',
    },
    {
      user_id: users[4]?.id,
      title: 'Draft: Kubernetes Basics',
      content: 'An introduction to container orchestration with Kubernetes.',
      status: 'draft',
    },
  ];

  for (const post of posts) {
    try {
      await pool.query(
        `INSERT INTO posts (user_id, title, content, status)
         VALUES ($1, $2, $3, $4)`,
        [post.user_id, post.title, post.content, post.status]
      );
    } catch (error) {
      console.error(`    Error seeding post "${post.title}":`, error);
      throw error;
    }
  }

  const result = await pool.query('SELECT COUNT(*) FROM posts');
  const publishedResult = await pool.query("SELECT COUNT(*) FROM posts WHERE status = 'published'");
  console.log(`    ✓ ${posts.length} posts seeded (${result.rows[0].count} total, ${publishedResult.rows[0].count} published)`);
}
