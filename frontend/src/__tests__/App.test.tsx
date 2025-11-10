/**
 * App Component Tests
 * Tests the main App component functionality
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import App from '../App';

// Mock fetch globally
global.fetch = vi.fn();

describe('App Component', () => {
  beforeEach(() => {
    // Reset fetch mock before each test
    vi.resetAllMocks();
  });

  it('renders the main heading', () => {
    // Mock successful API response
    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        message: 'Test API',
        version: '1.0.0',
        environment: 'test',
      }),
    });

    render(<App />);
    const heading = screen.getByText(/Wander Dev Environment/i);
    expect(heading).toBeInTheDocument();
  });

  it('shows loading state initially', () => {
    // Mock pending API response
    (global.fetch as any).mockImplementationOnce(
      () => new Promise(() => {}) // Never resolves
    );

    render(<App />);
    expect(screen.getByText(/Loading.../i)).toBeInTheDocument();
  });

  it('displays API status when successfully loaded', async () => {
    // Mock successful API response
    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        message: 'Wander API is running',
        version: '1.0.0',
        environment: 'test',
      }),
    });

    render(<App />);

    // Wait for API status to load
    await waitFor(() => {
      expect(screen.getByText(/Connected to API/i)).toBeInTheDocument();
    });

    expect(screen.getByText(/Wander API is running/i)).toBeInTheDocument();
    expect(screen.getByText(/1.0.0/i)).toBeInTheDocument();
  });

  it('displays error message when API fetch fails', async () => {
    // Mock failed API response
    (global.fetch as any).mockRejectedValueOnce(new Error('Network error'));

    render(<App />);

    // Wait for error to be displayed
    await waitFor(() => {
      expect(screen.getByText(/Error: Network error/i)).toBeInTheDocument();
    });
  });

  it('renders API health check link', async () => {
    // Mock successful API response
    (global.fetch as any).mockResolvedValueOnce({
      ok: true,
      json: async () => ({
        message: 'Test',
        version: '1.0.0',
        environment: 'test',
      }),
    });

    render(<App />);

    const healthLink = await screen.findByText(/API Health Check/i);
    expect(healthLink).toBeInTheDocument();
    expect(healthLink).toHaveAttribute('href', expect.stringContaining('/health'));
  });
});
